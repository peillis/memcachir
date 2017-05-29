defmodule Memcachir do
  @moduledoc """
  Module with a friendly API for memcached servers.

  It provides connection pooling, and cluster support.

  ## Example

      {:ok, "world"} = Memcachir.set("hello", "world")
      {:ok, "world"} = Memcachir.get("hello")

  """
  use Application

  alias Memcachir.Util

  require IEx
  @doc """
  Starts application.
  """
  def start(_type, _args) do
    servers =
      case Application.get_env(:memcachir, :elasticache) do
        nil ->
          Util.read_config_hosts(Application.get_env(:memcachir, :hosts))
        elasticache ->
          Util.read_config_elasticache(elasticache)
      end

    if length(servers) > 1 do
      raise ArgumentError, message: "multiple hosts not yet allowed"
    end

    [{hostname, port}] = servers
    options =
      Application.get_all_env(:memcachir)
      |> Keyword.put(:hostname, hostname)
      |> Keyword.put(:port, port)
    pool_options = Application.get_env(:memcachir, :pool, [])

    Memcachir.Supervisor.start_link(options, pool_options)
  end

  @doc """
  Gets the value associated with the key. Returns `{:error, "Key not found"}`
  if the given key doesn't exist.
  """
  def get(key, opts \\ []) do
    execute(&Memcache.get/3, [key, opts])
  end

  @doc """
  Sets the key to value.
  """
  def set(key, value, opts \\ []) do
    execute(&Memcache.set/4, [key, value, opts])
  end

  @doc """
  Removes the item with the specified key. Returns `{:ok, :deleted}`
  """
  def delete(key) do
    execute(&Memcache.delete/2, [key])
  end

  @doc """
  Removes all the items from the server. Returns `{:ok, :flushed}`.
  """
  def flush(opts \\ []) do
    execute(&Memcache.flush/2, [opts])
  end

  def execute(fun, args \\ []) do
    :poolboy.transaction(Memcachir.Pool, fn(worker) ->
      apply(fun, [worker | args])
    end)
  end
end
