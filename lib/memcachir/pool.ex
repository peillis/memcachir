defmodule Memcachir.Pool do

  @default_opts [
    strategy: :lifo,
    size: 10,
    max_overflow: 10,
    worker_module: Memcachir.Worker
  ]

  def start_link(options, pool_options) do
    pool_options =
      @default_opts
      |> Keyword.merge(pool_options)
    :poolboy.start_link(pool_options, options)
  end

end
