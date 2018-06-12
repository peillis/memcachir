defmodule Memcachir.Cluster do
  use GenServer
  require Logger

  alias Memcachir.Util

  def start_link(options) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  def init(options) do
    servers = Util.get_servers(options)
    Logger.info("starting cluster with servers: #{inspect servers}")

    ring =
      servers
      |> Enum.reduce(HashRing.new(), fn({host, port}, ring) ->
        HashRing.add_node(ring, {host, port})
      end)

    {:ok, ring}
  end

  def servers() do
    GenServer.call(__MODULE__, :servers)
  end

  def key_to_node(key) do
    GenServer.call(__MODULE__, {:node, key})
  end

  def handle_call(:servers, _from, ring) do
    {:reply, HashRing.nodes(ring), ring}
  end

  def handle_call({:node, key}, _from, ring) do
    {:reply, HashRing.key_to_node(ring, key), ring}
  end
end
