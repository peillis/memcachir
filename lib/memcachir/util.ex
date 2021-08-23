defmodule Memcachir.Util do
  @moduledoc """
  Utilities to read configuration.
  """

  @retry_opts Application.get_env(:memcachir, __MODULE__, [])
              |> Keyword.get(:retry, [])

  @retry_opts  Keyword.merge([retry_base: 10, jitter: 10, max_retries: 3], @retry_opts)
  @jitter      Keyword.get(@retry_opts, :jitter)
  @retry_base  Keyword.get(@retry_opts, :retry_base)
  @max_retries Keyword.get(@retry_opts, :max_retries)

  @doc """
  Keep service discovery inference backwards compatible for now.

  The cascade is:

    * if `:memcachir`, `:elasticache` is set, use `Memcachir.ServiceDiscovery.Elasticache`
    * if `:memcachir`, `:hosts` is set, use `Memcachir.ServiceDiscovery.Hosts`
    * otherwise use what is configured in `:memcachir`, `:service_discovery` (defaulting to Hosts)
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

  def retry(fun, opts \\ [], retries \\ 0) do
    jitter = Keyword.get(opts, :jitter, @jitter)
    base   = Keyword.get(opts, :retry_base, @retry_base)
    max    = Keyword.get(opts, :max_retries, @max_retries)

    case {fun.(), retries < max} do
      {{:error, _error}, true} ->
        jitter     = :rand.uniform(jitter)
        sleep_time = :math.pow(2, retries) |> round()
        :timer.sleep(base * sleep_time + jitter)

        retry(fun, opts, retries + 1)
      {result, _} -> result
    end
  end
end
