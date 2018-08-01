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
    Cluster.servers() |> Enum.map(&Util.to_server_id(&1))
  end

  defp execute(fun, nodes, args \\ [])

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
    :poolboy.transaction(node, fn worker ->
      apply(fun, [worker | args])
    end)
  end

  defp key_to_node(key) do
    case Cluster.key_to_node(key) do
      {:error, {:invalid_ring, reason}} -> {:error, reason}
      node -> {:ok, Util.to_server_id(node)}
    end
  end
end
