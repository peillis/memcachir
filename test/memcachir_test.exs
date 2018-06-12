defmodule MemcachirTest do
  use ExUnit.Case, async: false

  alias Memcachir.{ClusterSupervisor, HealthCheck}


  setup_all do
    GenServer.stop(ClusterSupervisor)

    opts = [
      hosts: ["localhost:11211"],
      pool: [size: 2]
    ]
    {:ok, _} = ClusterSupervisor.start_link(opts)

    :ok
  end

  setup do
    assert {:ok} == Memcachir.flush()
    :ok
  end


  test "basic set get" do
    assert {:ok} == Memcachir.set("hello", "world")
    assert {:ok, "world"} == Memcachir.get("hello")
  end

  test "set with ttl" do
    assert {:ok} == Memcachir.set("hello", "world", ttl: 1)
    assert {:ok, "world"} == Memcachir.get("hello")
    :timer.sleep(1000)
    assert {:error, "Key not found"} == Memcachir.get("hello")
  end

  test "delete" do
    assert {:ok} == Memcachir.set("hello", "world")
    assert {:ok} == Memcachir.delete("hello")
    assert {:error, "Key not found"} == Memcachir.get("hello")
  end

  test "flush" do
    assert {:ok} == Memcachir.set("hello", "world")
    assert {:ok} == Memcachir.flush()
    assert {:error, "Key not found"} == Memcachir.get("hello")
  end
end
