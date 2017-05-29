defmodule MemcachirTest do
  use ExUnit.Case

  setup_all do
    :timer.sleep(5000)
  end

  setup do
    assert {:ok} == Memcachir.flush()
    Application.delete_env(:memcachir, :namespace)
    Application.delete_env(:memcachir, :ttl)
    :ok
  end

  test "basic set get" do
    assert {:ok} == Memcachir.set("hello", "world")
    assert {:ok, "world"} == Memcachir.get("hello")
  end

  test "set with ttl" do
    assert {:ok} == Memcachir.set("hello", "world", ttl: 2)
    assert {:ok, "world"} == Memcachir.get("hello")
    :timer.sleep(2000)
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
