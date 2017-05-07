Code.require_file "./bench_utils.exs", __DIR__

defmodule McdBench do
  use Benchfella
  import BenchUtils

  setup_all do
    Memcachir.start([], [])
    {:ok, "world"} = Memcachir.set("hello", "world")
    {:ok, _} = Memcachir.set("hello_large", random_string())
    {:ok, "hey"}
  end

  bench "GET" do
    {:ok, "world"} = Memcachir.get("hello")
  end

  bench "SET" do
    {:ok, "world"} = Memcachir.set("hello", "world")
  end

  bench "SET LARGE", [large_blob: random_string()] do
    {:ok, _} = Memcachir.set("hello", large_blob)
  end

  bench "GET LARGE" do
    {:ok, _} = Memcachir.get("hello_large")
  end
end
