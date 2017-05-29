defmodule Memcachir.Pool do

  @default_opts [
    strategy: :lifo,
    size: 10,
    max_overflow: 10,
    worker_module: Memcachir.Worker,
    name: {:local, __MODULE__}
  ]

  def start_link(hosts, opts) do
    pool_options = @default_opts |> Keyword.merge(opts)
    :poolboy.start_link(pool_options, hosts)
  end

end
