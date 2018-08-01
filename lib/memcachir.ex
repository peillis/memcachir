defmodule Memcachir do
  @moduledoc """
  Module with a friendly API for memcached servers.

  It provides connection pooling, and cluster support.

  ## Example

      {:ok} = Memcachir.set("hello", "world")
      {:ok, "world"} = Memcachir.get("hello")

  """
  use Application

  alias Memcachir.Util

  @doc """
  Starts application.
  """
  def start(_type, _args) do
    servers = get_servers()

    # Build the hashring
    {:ok, _pid} = HashRing.Managed.new(:memcachir_ring)
    Enum.each(servers, fn({host, port}) ->
      :ok = HashRing.Managed.add_node(
              :memcachir_ring, Util.host_to_atom(host, port))
    end)

    options =
      Application.get_all_env(:memcachir)
      |> Keyword.put(:servers, servers)
    pool_options = Application.get_env(:memcachir, :pool, [])

    Memcachir.Supervisor.start_link(options, pool_options)
  end

  @doc """
  Gets the value associated with the key. Returns `{:error, "Key not found"}`
  if the given key doesn't exist.
  """
  def get(key, opts \\ []) do
    node = key_to_node(key)
    execute(&Memcache.get/3, node, [key, opts])
  end

  @doc """
  Accepts a list of mcached keys, and returns either `{:ok, %{key => val}}` for each
  found key or `{:error, any}`
  """
  def mget(keys, opts \\ []) do
    grouped_keys = Enum.group_by(keys, &key_to_node/1)
    exec_parallel(&Memcache.multi_get/3, grouped_keys, [opts])
  end

  @doc """
  Accepts a list of `{key, val}` pairs and returns the store results for each
  node touched
  """
  def mset(commands, opts \\ []) do
    grouped_keys = Enum.group_by(commands, &key_to_node(elem(&1, 0)))
    exec_parallel(&Memcache.multi_set/3, grouped_keys, [opts], &Enum.concat/2)
  end

  @doc """
  Multi-set with cas option
  """
  def mset_cas(commands, opts \\ []) do
    grouped_keys = Enum.group_by(commands, &key_to_node(elem(&1, 0)))
    exec_parallel(&Memcache.multi_set_cas/3, grouped_keys, [opts], &Enum.concat/2)
  end

  @doc """
  increments the key by value
  """
  def incr(key, value \\ 1, opts \\ []) do
    node = key_to_node(key)
    execute(&Memcache.incr/3, node, [key, [{:by, value} | opts]])
  end

  @doc """
  Sets the key to value.
  """
  def set(key, value, opts \\ []) do
    node = key_to_node(key)
    execute(&Memcache.set/4, node, [key, value, opts])
  end

  @doc """
  Removes the item with the specified key. Returns `{:ok, :deleted}`
  """
  def delete(key) do
    node = key_to_node(key)
    execute(&Memcache.delete/2, node, [key])
  end

  @doc """
  Removes all the items from the server. Returns `{:ok}`.
  """
  def flush(opts \\ []) do
    nodes = HashRing.Managed.nodes(:memcachir_ring)
    execute(&Memcache.flush/2, nodes, [opts])
  end

  def execute(fun, nodes, args \\ [])
  def execute(fun, [node | nodes], args) do
    if length(nodes) > 0 do
      execute(fun, nodes, args)
    end
    execute(fun, node, args)
  end
  def execute(fun, node, args) do
    :poolboy.transaction(node, fn(worker) ->
      apply(fun, [worker | args])
    end)
  end

  @doc """
  Accepts a memcache operation closure, a grouped map of %{node => args} and executes
  the operations in parallel for all given nodes.  The result is of form {:ok, enumerable}
  where enumerable is the merged result of all operations.

  Additionally, you can pass `args` to supply memcache ops to each of the executions
  and `merge_fun` (a 2-arity func) which configures how the result is merged into the final result set.
  For instance, `mget/2` returns a map of key, val pairs in its result, and utilizes `Map.merge/2`.
  """
  def exec_parallel(fun, grouped, args \\ [], merge_fun \\ &Map.merge/2) do
    grouped
    |> Enum.map(fn {node, val} -> Task.async(fn -> execute(fun, node, [val | args]) end) end)
    |> Enum.map(&Task.await/1)
    |> Enum.reduce({%{}, []}, fn 
      {:ok, result}, {acc, errors} -> {merge_fun.(acc, result), errors}
      error, {acc, errors} -> {acc, [error | errors]}
    end)
    |> case do
      {map, [error | _]} when map_size(map) == 0 -> error
      {result, _} -> {:ok, result}
    end
  end

  defp key_to_node(key) do
    HashRing.Managed.key_to_node(:memcachir_ring, key)
  end

  # Returns a list like [{host1, port1}, {host2, port2}, ...]
  # from the configured hosts parameter or reading it from elasticache
  defp get_servers() do
    case Application.get_env(:memcachir, :elasticache) do
      nil ->
        Util.read_config_hosts(Application.get_env(:memcachir, :hosts))
      elasticache ->
        Util.read_config_elasticache(elasticache)
    end
  end

end
