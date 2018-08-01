defmodule Memcachir.Supervisor do
  use Supervisor
  require Logger

  alias Memcachir.{Cluster, HealthCheck, Pool}

  def start_link(options) do
    Supervisor.start_link(__MODULE__, options, name: __MODULE__)
  end

  def init(options) do
    children = [
      # needs to be started FIRST
      worker(Cluster, [options]),
      worker(HealthCheck, [options]),
      supervisor(Pool, [options])
    ]

    # if the health check dies (e.g. because a node was added/removed), restart everything
    supervise(children, strategy: :one_for_all)
  end
end
