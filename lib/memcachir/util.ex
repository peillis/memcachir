defmodule Memcachir.Util do
  @moduledoc """
  Utilities to read configuration.
  """

  require Logger

  # Returns a list like [{host1, port1}, {host2, port2}, ...]
  # from the configured hosts parameter or reading it from elasticache
  def get_servers(options) do
    case Keyword.get(options, :elasticache) do
      nil -> read_config_hosts(Keyword.get(options, :hosts))
      host -> read_config_elasticache(host)
    end
  end

  @doc """
  Reads the hosts configuration.
  """
  def read_config_hosts(hosts) when is_list(hosts) do
    Enum.map(hosts, &parse_hostname/1)
  end
  def read_config_hosts(hosts) when is_binary(hosts) do
    read_config_hosts([hosts])
  end
  def read_config_hosts(nil) do
    read_config_hosts("localhost")
  end
  def read_config_hosts(_) do
    raise_error()
  end

  @doc """
  Reads the elasticache configuration.
  """
  def read_config_elasticache(host, elasticache_mod \\ Elasticachex)

  def read_config_elasticache(host, elasticache_mod) when is_binary(host) do
    {host, port} = parse_hostname(host)
    case elasticache_mod.get_cluster_info(host, port) do
      {:ok, hosts, _version} -> read_config_hosts(hosts)
      {:error, reason} ->
        Logger.error("unable to fetch ElastiCache servers: #{inspect reason}")
        []
    end
  end
  def read_config_elasticache(_, _) do
    raise_error()
  end

  defp parse_hostname(hostname) do
    case String.split(hostname, ":") do
      [hostname, port] ->
        {String.to_charlist(hostname), String.to_integer(port)}
      [hostname] ->
        {String.to_charlist(hostname), 11_211}
      _ -> raise_error()
    end
  end

  defp raise_error do
    raise ArgumentError, message: "invalid configuration"
  end

  @doc """
  Returns an atom based on hostname and port
  """
  def to_server_id({host, port}) do
    String.to_atom("#{host}:#{port}")
  end
end
