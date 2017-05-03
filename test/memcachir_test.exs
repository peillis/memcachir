defmodule MemcachirTest do
  use ExUnit.Case

  setup do
    assert {:ok, :flushed} == Memcachir.flush()
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
    assert {:error, :notfound} == Memcachir.get("hello")
  end

  test "delete" do
    assert {:ok, "world"} == Memcachir.set("hello", "world")
    assert {:ok, :deleted} == Memcachir.delete("hello")
    assert {:error, :notfound} == Memcachir.get("hello")
  end

  test "flush" do
    assert {:ok, "world"} == Memcachir.set("hello", "world")
    assert {:ok, :flushed} == Memcachir.flush()
    assert {:error, :notfound} == Memcachir.get("hello")
  end

  test "config namespace" do
    Application.put_env(:memcachir, :namespace, "test")
    assert {:ok, "world"} == Memcachir.set("hello", "world")
    assert {:ok, "world"} == Memcachir.get("hello")
    pid = :poolboy.checkout(Memcachir.Pool)
    assert {:ok, "world"} == :mcd.get(pid, "test:hello")
    :ok = :poolboy.checkin(Memcachir.Pool, pid)
  end

  test "config ttl" do
    Application.put_env(:memcachir, :ttl, 2)
    assert {:ok, "world"} == Memcachir.set("hello", "world")
    assert {:ok, "world"} == Memcachir.get("hello")
    :timer.sleep(2000)
    assert {:error, :notfound} == Memcachir.get("hello")
  end

end
