defmodule Memcachir.Pool do
  use Supervisor

  alias Memcachir.{Cluster, Util}

  @default_pool_options [
    strategy: :lifo,
    size: 10,
    max_overflow: 10,
    worker_module: Memcache
  ]

  def start_link(options) do
    Supervisor.start_link(__MODULE__, options, name: __MODULE__)
  end

  def init(options) do
    Cluster.servers()
    |> Enum.map(fn {host, port} ->
      pool_name = Util.to_server_id({host, port})

      options =
        options
        |> Keyword.put(:hostname, host)
        |> Keyword.put(:port, port)

      pool_options =
        @default_pool_options
        |> Keyword.merge(Keyword.get(options, :pool, []))
        |> Keyword.put(:name, {:local, pool_name})

      worker(:poolboy, [pool_options, options], id: pool_name)
    end)
    |> supervise(strategy: :one_for_one)
  end
end
