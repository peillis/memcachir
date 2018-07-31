defmodule Memcachir.HealthCheck do
  use GenServer

  alias Memcachir.{Cluster, Util}

  @default_delay 60_000

  def start_link(options) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  def init(options) do
    # only need to poll if using ElastiCache
    if Keyword.has_key?(options, :elasticache) do
      schedule_health_check(options)
    end

    {:ok, options}
  end

  def handle_info(:check, options) do
    known_servers = Cluster.servers() |> Enum.into(MapSet.new)
    actual_servers = Util.get_servers(options) |> Enum.into(MapSet.new)

    if MapSet.equal?(known_servers, actual_servers) do
      schedule_health_check(options)
      {:noreply, options}
    else
      {:stop, "ElastiCache servers changed from #{inspect known_servers} to #{inspect actual_servers}", options}
    end
  end

  defp schedule_health_check(options) do
    delay = Keyword.get(options, :health_check) || @default_delay
    Process.send_after(self(), :check, delay)
  end
end
