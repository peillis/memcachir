defmodule FailureHandlingTest do
  use ExUnit.Case, async: false

  alias Memcachir.Cluster


  @cluster ["localhost|localhost|11211", "localhost|127.0.0.1|11211"]


  setup do
    assert :ok == Application.stop(:memcachir)
    Application.delete_env(:memcachir, :hosts)
    Application.put_env(:memcachir, :elasticache, "localhost:11211")
    assert :ok == Application.start(:memcachir)
    :ok
  end


  test "survive ElastiCache failure" do
    MockSocketModule.update([])

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

    # one node is removed

    [_ | other_servers] = @cluster
    MockSocketModule.update(other_servers)

    assert [{'127.0.0.1', 11211}] == Cluster.servers()
    assert {:ok, "world"} == Memcachir.get("hello")

    # one node is added

    MockSocketModule.update(@cluster)

    assert [{'localhost', 11211}, {'127.0.0.1', 11211}] == Cluster.servers()
    assert {:ok, "world"} == Memcachir.get("hello")
  end
end
