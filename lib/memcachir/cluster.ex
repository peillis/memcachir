defmodule Memcachir.Cluster do
  use GenServer
  require Logger

  alias Memcachir.ServiceDiscovery
  @default_delay Application.get_env(:memcachir, :health_check, 60_000)
  @table_name :memcachir_servers

  def start_link(options) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  def init(_) do
    servers = ServiceDiscovery.nodes()
    Logger.info("starting cluster with servers: #{inspect(servers)}")

    ring = Enum.reduce(servers, HashRing.new(), &HashRing.add_node(&2, &1))

    table = :ets.new(@table_name, [:set, :protected, :named_table])
    :ets.insert(table, {:hash_ring, ring})
    schedule_healthcheck()

    {:ok, table}
  end

  def servers() do
    case get_ring() do
      {:ok, ring} -> HashRing.nodes(ring)
      _ -> []
    end
  end

  def key_to_node(key) do
    with {:ok, ring} <- get_ring(), do: HashRing.key_to_node(ring, key)
  end

  def keys_to_nodes(keys) do
    with {:ok, ring} <- get_ring(), do: get_nodes(keys, ring)
  end

  def handle_info(:health_check, table) do
    schedule_healthcheck()
    servers = ServiceDiscovery.nodes() |> MapSet.new()
    current = servers() |> MapSet.new()

    added   = MapSet.difference(servers, current) |> MapSet.to_list()
    removed = MapSet.difference(current, servers) |> MapSet.to_list()

    handle_diff(added, removed, table)
  end

  defp handle_diff([], [], table), do: {:noreply, table}
  defp handle_diff(add, remove, table) do
    {:ok, ring} = get_ring()
    Logger.info "Added #{inspect(add)} servers to cluster"
    Logger.info "Removed #{inspect(remove)} servers from cluster"

    ring = Enum.reduce(add, ring, &HashRing.add_node(&2, &1))
    ring = Enum.reduce(remove, ring, &HashRing.remove_node(&2, &1))
    :ets.insert(table, {:hash_ring, ring})
    Supervisor.stop(Memcachir.Pool, :normal)
    {:noreply, table}
  end

  defp get_ring() do
    case :ets.lookup(@table_name, :hash_ring) do
      [{:hash_ring, ring}] -> {:ok, ring}
      _ -> {:error, :not_found}
    end
  end

  defp schedule_healthcheck() do
    delay = Application.get_env(:memcachir, :health_check, @default_delay)
    Process.send_after(self(), :health_check, delay)
  end

  defp get_nodes(keys, ring) do
    nodes = Enum.map(keys, &HashRing.key_to_node(ring, &1))

    case nodes do
      [{:error, _} = error | _] -> error
      _ -> {:ok, keys |> Enum.zip(nodes) |> Enum.into(%{})}
    end
  end
end
