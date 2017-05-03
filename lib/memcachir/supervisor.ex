defmodule Memcachir.Supervisor do
  use Supervisor

  def start_link(hosts, pool_options) do
    Supervisor.start_link(__MODULE__, [hosts, pool_options])
  end

  def init([hosts, pool_options]) do
    children = [
      worker(Memcachir.Pool, [hosts, pool_options])
    ]
    opts = [strategy: :one_for_one]

    supervise(children, opts)
  end
end
