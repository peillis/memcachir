defmodule Memcachir.ServiceDiscovery.Elasticache do
  @moduledoc """
  Utilizes the elasticache cluster endpoint to infer node addresses.
  """
  @behaviour Herd.Discovery
  @retry_opts Application.get_env(:memcachir, __MODULE__, [])
              |> Keyword.get(:retry, [])
  alias Memcachir.Util
  require Logger

  def nodes() do
    {host, port} = endpoint() |> Util.parse_hostname()
    mod  = elasticache_module()
    host = to_string(host)

    (fn -> infer_nodes(mod, host, port) end)
    |> Util.retry(@retry_opts)
    |> case do
      {:ok, hosts, _version} -> Util.parse_hostname(hosts)
      {:error, reason} ->
        Logger.error("unable to fetch Elasticache servers: #{inspect(reason)}")
        []
    end
  end

  defp infer_nodes(module, host, port), do: module.get_cluster_info(host, port)

  defp endpoint(), do: Application.get_env(:memcachir, :elasticache) || config()[:endpoint]

  defp config(), do: Application.get_env(:memcachir, __MODULE__, [])

  defp elasticache_module(), do: Application.get_env(:memcachir, :elasticache_mod, Elasticachex)
end
