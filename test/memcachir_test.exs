defmodule MemcachirTest do
  use ExUnit.Case, async: false

  setup do
    Application.delete_env(:memcachir, :elasticache)
    Application.put_env(:memcachir, :hosts, "localhost:11211")
    start_supervised(Memcachir.Supervisor)
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
    :timer.sleep(1001)
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

  test "mget" do
    {:ok} = Memcachir.set("hello", "world")
    {:ok} = Memcachir.set("hey", "world!")

    {:ok, result} = Memcachir.mget(["hello", "hey"])

    assert result["hello"] == "world"
    assert result["hey"] == "world!"
  end

  test "incr" do
    {:ok} = Memcachir.set("incr", "1")

    {:ok, result} = Memcachir.incr("incr")

    assert result == 2
  end

  test "mset" do
    {:ok, _} = Memcachir.mset([{"hello", "world"}, {"hey", "world!"}])

    {:ok, result} = Memcachir.mget(["hello", "hey"])

    assert result["hello"] == "world"
    assert result["hey"] == "world!"
  end
end
