Code.require_file "./bench_utils.exs", __DIR__

defmodule McdBench do
  use Benchfella
  import BenchUtils

  setup_all do
    {:ok, pid} = :mero_sup.start_link([{:default, [{:servers, [{'localhost', 11211}]}, {:sharding_algorithm, {:mero, :shard_crc32}}, {:workers_per_shard, 1}, {:pool_worker_module, :mero_wrk_tcp_binary}]}])
    :timer.sleep(5000)
    :ok = :mero.set(:default, "hello", "world", 0, 5000)
    :ok = :mero.set(:default, "hello_large", random_string(), 0, 5000)
    {:ok, pid}
  end

  bench "GET" do
    {"hello", "world"} = :mero.get(:default, "hello")
  end

  bench "SET" do
    :ok = :mero.set(:default, "hello", "world", 0, 5000)
  end

  bench "SET LARGE", [large_blob: random_string()] do
    :ok = :mero.set(:default, "hello", large_blob, 0, 5000)
  end

  bench "GET LARGE" do
    {"hello_large", _} = :mero.get(:default, "hello_large")
  end
end
