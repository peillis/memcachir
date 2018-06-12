defmodule Memcachir.PoolSupervisor do
  use Supervisor

  alias Memcachir.{Cluster, Util}

  def start_link(options) do
    Supervisor.start_link(__MODULE__, options, name: __MODULE__)
  end

  def init(options) do
    pool_options = Keyword.get(options, :pool, [])

    children =
      Cluster.servers()
      |> Enum.map(fn({host, port}) ->
        pool_name = Util.to_server_id({host, port})

        options =
          options
          |> Keyword.put(:hostname, host)
          |> Keyword.put(:port, port)

        pool_options =
          pool_options
          |> Keyword.put(:name, {:local, pool_name})

        worker(Memcachir.Pool, [options, pool_options], id: pool_name)
      end)

    supervise(children, [strategy: :one_for_one])
  end
end
