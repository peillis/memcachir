defmodule Memcachir.Util do
  @moduledoc """
  Utilities to read configuration.
  """

  @retry_base 10
  @jitter     10
  @max_retries 3

  @doc """
  Keep service discovery inference backwards compatible for now. The cascade is:

  * if :memcachir, :elasticache is set, use Memcachir.ServiceDiscovery.Elasticache
  * if :memcachir, :hosts is set, use Memcachir.ServiceDiscovery.Hosts
  * otherwise use what is configured in :memcachir, :service_discovery (defaulting to Hosts)
  """
  def determine_service_discovery() do
    elasticache = Application.get_env(:memcachir, :elasticache)
    hosts = Application.get_env(:memcachir, :hosts)

    case {elasticache, hosts} do
      {elasticache, _} when is_binary(elasticache) -> Memcachir.ServiceDiscovery.Elasticache
      {_, hosts} when is_list(hosts) or is_binary(hosts) -> Memcachir.ServiceDiscovery.Hosts
      _ -> Application.get_env(:memcachir, :service_discovery, Memcachir.ServiceDiscovery.Hosts)
    end
  end

  def parse_hostname(hostnames) when is_list(hostnames), do: Enum.map(hostnames, &parse_hostname/1)
  def parse_hostname(hostname) do
    case String.split(hostname, ":") do
      [hostname, port] -> {String.to_charlist(hostname), String.to_integer(port)}
      [hostname] -> {String.to_charlist(hostname), 11_211}
      _ -> raise ArgumentError, message: "invalid configuration"
    end
  end

  def retry(fun, retries \\ 0, max_retries \\ @max_retries) do
    case {fun.(), retries < max_retries} do
      {{:error, error}, true} ->
        jitter     = :rand.uniform(@jitter)
        sleep_time = :math.pow(2, retries) |> round()
        :timer.sleep(@retry_base*sleep_time + jitter)

        retry(fun, retries + 1, max_retries)
      {result, _} -> result
    end
  end
end
