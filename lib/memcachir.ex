defmodule Memcachir.Cluster do
  @moduledoc """
  Manages cluster state with a regular healthcheck to the configured service discovery
  mechanism.  Configure it with:
  ```
  config :memcachir, :memcachir_cluster, discovery: MyServiceDiscovery
  ```
  Additionally the health check can be configured with
  ```
  config :memcachir, :health_check, 10_000
  ```
  """
  use Herd.Cluster, otp_app: :memcachir,
                    pool: Memcachir.Pool,
                    discovery: Memcachir.ServiceDiscovery,
                    health_check: Application.get_env(:memcachir, :health_check, 60_000)
end

defmodule Memcachir.Pool do
  @moduledoc """
  Dynamic supervisor for connection pooling.  If you want to modify the poolboy params,
  configure it with:
  ```
  config :memcachir, Memcachir.Pool, poolboy: :params
  ```
  Additionally, params that will be sent to the memcachex workers are all found at the top
  level of `:memcachir` config
  """
  use Herd.Pool, otp_app: :memcachir

  def worker_config({host, port}) do
    memcachir_config()
    |> Keyword.put(:hostname, host)
    |> Keyword.put(:port, port)
  end

  def pool_config(pool) do
    Keyword.put_new(pool, :worker_module, Memcache)
  end

  defp memcachir_config, do: Application.get_all_env(:memcachir)
end

defmodule Memcachir.Supervisor do
  @moduledoc """
  Supervises the memcachir cluster, pool and registry (which is used internally)
  """
  use Herd.Supervisor, otp_app: :memcachir,
                       pool: Memcachir.Pool,
                       cluster: Memcachir.Cluster
end

defmodule Memcachir do
  @moduledoc """
  TODO
  """
  use Memcachir.Plugin, otp_app: :memcachir,
                        pool: Memcachir.Pool,
                        cluster: Memcachir.Cluster
end
