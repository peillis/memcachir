defmodule Memcachir do
  @moduledoc """
  Module with a friendly API for memcached servers.

  It provides connection pooling, and cluster support.

  ## Example

      {:ok} = Memcachir.set("hello", "world")
      {:ok, "world"} = Memcachir.get("hello")

  """
  use Application

  alias Memcachir.{Cluster, Supervisor, Util}

  def start(_type, _args) do
    opts = Application.get_all_env(:memcachir)
    Supervisor.start_link(opts)
  end

  @doc """
  Gets the value associated with the key. Returns `{:error, "Key not found"}`
  if the given key doesn't exist.
  """
  def get(key, opts \\ []) do
    case key_to_node(key) do
      {:ok, node} -> execute(&Memcache.get/3, node, [key, opts])
      {:error, reason} -> {:error, "unable to get: #{reason}"}
    end
  end

  @doc """
  Accepts a list of mcached keys, and returns either `{:ok, %{key => val}}` for each
  found key or `{:error, any}`
  """
  def mget(keys, opts \\ []) do
    case group_by_node(keys) do
      {:ok, grouped_keys} -> exec_parallel(&Memcache.multi_get/3, grouped_keys, [opts])
      {:error, reason} -> {:error, "unable to get: #{reason}"}
    end
  end

  @doc """
  Accepts a list of `{key, val}` pairs and returns the store results for each
  node touched
  """
  def mset(commands, opts \\ []) do
    case group_by_node(commands, &elem(&1, 0)) do
      {:ok, grouped_keys} -> exec_parallel(&Memcache.multi_set/3, grouped_keys, [opts], &Enum.concat/2)
      {:error, reason} -> {:error, "unable to set: #{reason}"}
    end
  end

  @doc """
  Multi-set with cas option
  """
  def mset_cas(commands, opts \\ []) do
    case group_by_node(commands, &elem(&1, 0)) do
      {:ok, grouped_keys} -> exec_parallel(&Memcache.multi_set_cas/3, grouped_keys, [opts], &Enum.concat/2)
      {:error, reason} -> {:error, "unable to set: #{reason}"}
    end
  end

  @doc """
  increments the key by value
  """
  def incr(key, value \\ 1, opts \\ []) do
    case key_to_node(key) do
      {:ok, node} -> execute(&Memcache.incr/3, node, [key, [{:by, value} | opts]])
      {:error, reason} -> {:error, "unable to inc: #{reason}"}
    end
  end

  @doc """
  Sets the key to value.
  """
  def set(key, value, opts \\ []) do
    case key_to_node(key) do
      {:ok, node} -> execute(&Memcache.set/4, node, [key, value, opts])
      {:error, reason} -> {:error, "unable to set: #{reason}"}
    end
  end

  @doc """
  Removes the item with the specified key. Returns `{:ok, :deleted}`
  """
  def delete(key) do
    case key_to_node(key) do
      {:ok, node} -> execute(&Memcache.delete/2, node, [key])
      {:error, reason} -> {:error, "unable to delete: #{reason}"}
    end
  end

  @doc """
  Removes all the items from the server. Returns `{:ok}`.
  """
  def flush(opts \\ []) do
    execute(&Memcache.flush/2, list_nodes(), [opts])
  end

  @doc """
  List all currently registered node names, like `[:"localhost:11211"]`.
  """
  def list_nodes() do
    Cluster.servers() 
    |> Enum.map(&Util.to_server_id(&1))
  end

  defp execute(_fun, [], _args) do
    {:error, "unable to flush: no_nodes"}
  end
  defp execute(fun, [node | nodes], args) do
    if length(nodes) > 0 do
      execute(fun, nodes, args)
    end

    execute(fun, node, args)
  end
  defp execute(fun, node, args) do
    try do
      :poolboy.transaction(node, &apply(fun, [&1 | args]))
    catch
      :exit, _ -> {:error, "Node not available"}
    end
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

  defp group_by_node(commands, get_key \\ fn k -> k end) do
    key_to_command = Enum.into(commands, %{}, fn c -> {get_key.(c), c} end)

    commands
    |> Enum.map(get_key)
    |> Cluster.keys_to_nodes()
    |> case do
      {:ok, keys_to_nodes} ->
        value_fn = fn {_, n} -> Util.to_server_id(n) end
        key_fn   = fn {k, _} -> key_to_command[k] end
        nodes_to_keys = Enum.group_by(keys_to_nodes, value_fn, key_fn)

        {:ok, nodes_to_keys}
      {:error, error} -> {:error, error}
    end
  end

  defp key_to_node(key) do
    case Cluster.key_to_node(key) do
      {:error, {:invalid_ring, reason}} -> {:error, reason}
      node -> {:ok, Util.to_server_id(node)}
    end
  end
end
