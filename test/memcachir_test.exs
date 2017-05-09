defmodule MemcachirTest do
  use ExUnit.Case

  setup_all do
    :timer.sleep(5000)
  end

  setup do
    assert [default: :ok] == Memcachir.flush()
    Application.delete_env(:memcachir, :namespace)
    Application.delete_env(:memcachir, :ttl)
    :ok
  end

  test "basic set get" do
    assert {:ok, "world"} == Memcachir.set("hello", "world")
    assert {:ok, "world"} == Memcachir.get("hello")
  end

  test "set with ttl" do
    assert {:ok, "world"} == Memcachir.set("hello", "world", 2)
    assert {:ok, "world"} == Memcachir.get("hello")
    :timer.sleep(2000)
    assert {:error, :not_found} == Memcachir.get("hello")
  end

  test "delete" do
    assert {:ok, "world"} == Memcachir.set("hello", "world")
    assert {:ok, :deleted} == Memcachir.delete("hello")
    assert {:error, :not_found} == Memcachir.get("hello")
  end

  test "flush" do
    assert {:ok, "world"} == Memcachir.set("hello", "world")
    assert [default: :ok] == Memcachir.flush()
    assert {:error, :not_found} == Memcachir.get("hello")
  end

  test "config namespace" do
    Application.put_env(:memcachir, :namespace, "test")
    assert {:ok, "world"} == Memcachir.set("hello", "world")
    assert {:ok, "world"} == Memcachir.get("hello")
    assert {"test:hello", "world"} == :mero.get(:default, "test:hello")
  end

  test "config ttl" do
    Application.put_env(:memcachir, :ttl, 2)
    assert {:ok, "world"} == Memcachir.set("hello", "world")
    assert {:ok, "world"} == Memcachir.get("hello")
    :timer.sleep(2000)
    assert {:error, :not_found} == Memcachir.get("hello")
  end

end
