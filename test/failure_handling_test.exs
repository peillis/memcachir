defmodule FailureHandlingTest do
  use ExUnit.Case, async: false

  alias Memcachir.Cluster

  @cluster ["localhost|localhost|11211", "localhost|127.0.0.1|11211"]

  setup do
    Application.delete_env(:memcachir, :hosts)
    Application.put_env(:memcachir, :elasticache, "localhost:11211")
    start_supervised(Memcachir.Supervisor)
    :ok
  end

  test "survive ElastiCache failure" do
    MockSocketModule.update([])

    assert {:ok} == Memcachir.set("hello", "world")
    assert Memcachir.get("hello") == {:ok, "world"}

    # it's back up
    MockSocketModule.update(@cluster)

    assert Memcachir.get("hello") == {:ok, "world"}
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
