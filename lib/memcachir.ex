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

  @timeout_write Application.get_env(:mero, :timeout_write, 5000)
  @timeout_read Application.get_env(:mero, :timeout_read, 30)

  @doc """
  Starts application.
  """
  def start(_type, _args) do

    servers = case Application.get_env(:memcachir, :elasticache) do
      nil ->
        Util.read_config_hosts(Application.get_env(:memcachir, :hosts))
      elasticache ->
        Util.read_config_elasticache(elasticache)
    end

    set_mero_env()

    {:ok, _pid} = :mero_sup.start_link([
      {:default, [
        {:servers, servers},
        {:sharding_algorithm, {:mero, :shard_crc32}},
        {:workers_per_shard, Application.get_env(:mero, :workers_per_shard)},
        {:pool_worker_module, :mero_wrk_tcp_binary}
      ]}
    ])
  end

  @doc """
  Gets the value associated with the key. Returns `{:error, :notfound}`
  if the given key doesn't exist.
  """
  def get(key) do
    case :mero.get(:default, key |> add_namespace, @timeout_read) do
      {:error, reason} -> {:error, reason}
      {_, :undefined}  -> {:error, :not_found}
      {_, value}       -> {:ok, value}
    end
  end

  @doc """
  Sets the key to value.
  """
  def set(key, value) do
    set(key, value, default_ttl())
  end

  @doc """
  Sets the key to value with a specified time to live.
  """
  def set(key, value, ttl) do
    nkey = key |> add_namespace
    case :mero.set(:default, nkey, value, ttl, @timeout_write) do
      {:error, reason} -> {:error, reason}
      :ok -> {:ok, value}
    end
  end

  @doc """
  Removes the item with the specified key. Returns `{:ok, :deleted}`
  """
  def delete(key) do
    case :mero.delete(:default, key |> add_namespace, @timeout_write) do
      {:error, reason} -> {:error, reason}
      :ok -> {:ok, :deleted}
    end
  end

  @doc """
  Removes all the items from the server. Returns `{:ok, :flushed}`.
  """
  def flush do
    :mero.flush_all(:default)
  end

  ## Private

  defp add_namespace(key) do
    case Application.get_env(:memcachir, :namespace) do
      nil -> key
      namespace -> "#{namespace}:#{key}"
    end
  end

  defp default_ttl do
    Application.get_env(:memcachir, :ttl, 0)
  end

  defp set_mero_env do
    Application.put_env(:mero, :workers_per_shard,
      Application.get_env(:memcachir, :workers_per_shard, 1))
    Application.put_env(:mero, :initial_connections_per_pool,
      Application.get_env(:memcachir, :initial_connections_per_pool, 20))
    Application.put_env(:mero, :min_free_connections_per_pool,
      Application.get_env(:memcachir, :min_free_connections_per_pool, 10))
    Application.put_env(:mero, :max_connections_per_pool,
      Application.get_env(:memcachir, :max_connections_per_pool, 50))

    Application.put_env(:mero, :timeout_read, 30)
    Application.put_env(:mero, :timeout_write, 5000)
    Application.put_env(:mero, :write_retries, 3)
    Application.put_env(:mero, :expiration_time, 86_400)
    Application.put_env(:mero, :connection_unused_max_time, 300_000)
    Application.put_env(:mero, :expiration_interval, 300_000)
    Application.put_env(:mero, :max_connection_delay_time, 5000)
    Application.put_env(:mero, :stat_event_callback, {:mero_stat, :noop})
  end

end
