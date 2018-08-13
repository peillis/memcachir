defmodule Memcachir.Supervisor do
  use Supervisor
  require Logger

  alias Memcachir.{Cluster, Pool}

  @supervisor_config Application.get_env(:memcachir, __MODULE__, [])

  def start_link(options) do
    Supervisor.start_link(__MODULE__, options, name: __MODULE__)
  end

  def init(options) do
    opts = Keyword.put(@supervisor_config, :strategy, :one_for_one)

    children = [
      # needs to be started FIRST
      worker(Registry, [[name: Memcachir.Registry, keys: :unique]]),
      supervisor(Pool, [options]),
      worker(Cluster, [options]),
    ]

    supervise(children, opts)
  end
end
