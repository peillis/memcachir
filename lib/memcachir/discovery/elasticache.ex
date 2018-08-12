defmodule Memcachir.ServiceDiscovery.Elasticache do
  @moduledoc """
  Utilizes the elasticache cluster endpoint to infer node addresses
  """
  alias Memcachir.Util
  require Logger

  def nodes() do
    {host, port} = endpoint() |> Util.parse_hostname()
    mod = elasticache_module()
    case mod.get_cluster_info(to_string(host), port) do
      {:ok, hosts, _version} -> Util.parse_hostname(hosts)
      {:error, reason} ->
        Logger.error("unable to fetch ElastiCache servers: #{inspect(reason)}")
        []
    end
  end

  defp endpoint(), do: Application.get_env(:memcachir, :elasticache) || config()[:endpoint]

  defp config(), do: Application.get_env(:memcachir, __MODULE__, [])

  defp elasticache_module(), do: Application.get_env(:memcachir, :elasticache_mod, Elasticachex)
end