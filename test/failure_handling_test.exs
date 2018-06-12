defmodule FailureHandlingTest do
  use ExUnit.Case, async: false

  alias Memcachir.{Cluster, ClusterSupervisor}

  @cluster ["localhost|localhost|11211", "localhost|127.0.0.1|11211"]

  setup_all do
    if Process.whereis(Memcachir.ClusterSupervisor) do
      GenServer.stop(Memcachir.ClusterSupervisor)
    end

    opts = [
      elasticache: "localhost:11211",
      pool: [size: 2]
    ]
    {:ok, _} = ClusterSupervisor.start_link(opts)

    :ok
  end


  test "survive ElastiCache failure" do
    # not initializing any servers

    assert {:error, "unable to set: no_nodes"} == Memcachir.set("hello", "world")
    assert {:error, "unable to delete: no_nodes"} == Memcachir.delete("hello")
    assert {:error, "unable to get: no_nodes"} == Memcachir.get("hello")
    assert {:error, "unable to flush: no_nodes"} == Memcachir.flush()

    MockSocketModule.update(@cluster) # it's back up

    assert {:ok} == Memcachir.set("hello", "world")
  end

  test "survive ElastiCache node replacement" do
    MockSocketModule.update(@cluster)
    Memcachir.set("hello", "world")

    # one node removed

    [_ | other_servers] = @cluster
    MockSocketModule.update(other_servers)

    assert [{'127.0.0.1', 11211}] == Cluster.servers()
    assert {:ok, "world"} == Memcachir.get("hello")

    # one node added

    MockSocketModule.update(@cluster)

    assert [{'localhost', 11211}, {'127.0.0.1', 11211}] == Cluster.servers()
    assert {:ok, "world"} == Memcachir.get("hello")
  end
end
