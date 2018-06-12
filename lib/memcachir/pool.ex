defmodule Memcachir.Pool do

  @default_pool_options [
    strategy: :lifo,
    size: 10,
    max_overflow: 10,
    worker_module: Memcachir.Worker
  ]

  def start_link(options, pool_options) do
    @default_pool_options
    |> Keyword.merge(pool_options)
    |> :poolboy.start_link(options)
  end
end
