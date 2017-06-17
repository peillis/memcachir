defmodule Memcachir.Supervisor do
  use Supervisor

  alias Memcachir.Util

  def start_link(options, pool_options) do
    Supervisor.start_link(__MODULE__, [options, pool_options])
  end

  def init([options, pool_options]) do
    # set a worker for every host in servers
    children = Enum.map(options[:servers], fn({host, port}) ->
      name = Util.host_to_atom(host, port)
      options =
        options
        |> Keyword.put(:hostname, host)
        |> Keyword.put(:port, port)
      pool_options =
        pool_options
        |> Keyword.put(:name, {:local, name})
      worker(Memcachir.Pool, [options, pool_options], id: name)
    end)

    opts = [strategy: :one_for_one]

    supervise(children, opts)
  end
end
