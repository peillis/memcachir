defmodule Memcachir.ClusterSupervisor do
  use Supervisor
  require Logger

  alias Memcachir.{Cluster, HealthCheck, PoolSupervisor}

  def start_link(options \\ Application.get_all_env(:memcachir)) do
    Supervisor.start_link(__MODULE__, options, name: __MODULE__)
  end

  def init(options) do
    children = [
      worker(Cluster, [options]), # needs to be started FIRST
      worker(HealthCheck, [options]),
      worker(PoolSupervisor, [options]),
    ]

    # if the health check dies (e.g. because a node was added/removed), restart everything
    supervise(children, strategy: :one_for_all)
  end
end
