defmodule Memcachir.Pool do
  use DynamicSupervisor

  alias Memcachir.Util

  @pool_config Application.get_all_env(:memcachir)  |> Keyword.get(:pool, [])
  @default_pool_config [
    strategy: :lifo,
    size: 10,
    max_overflow: 10,
    worker_module: Memcache
  ]

  @pool_config @default_pool_config |> Keyword.merge(@pool_config)

  def start_link(options) do
    DynamicSupervisor.start_link(__MODULE__, options, name: __MODULE__)
  end

  def init(_options) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child({host, port} = node) do
    pool_opts = @pool_config |> Keyword.put(:name, Util.to_server_id(node))
    opts = 
      config() 
      |> Keyword.put(:hostname, host)
      |> Keyword.put(:port, port)
    
    spec = %{id: :"#{host}_#{port}", start: {:poolboy, :start_link, [pool_opts, opts]}}

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def terminate_node({host, port}) do
    case Registry.lookup(Memcachir.Registry, :"#{host}_#{port}") do
      [{pid, _}] -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      _ -> :ok
    end
  end

  def initialize(servers), do: handle_diff(servers, [])

  def handle_diff(adds, removes) do
    for add <- adds, do: start_child(add)
    for remove <- removes, do: terminate_node(remove)
  end

  defp config(), do: Application.get_all_env(:memcachir)
end
