defmodule Memcachir.Util do
  @moduledoc """
  Utilities to read configuration.
  """

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
  def read_config_elasticache(elasticache) when is_binary(elasticache) do
    {:ok, hosts, _version} = Elasticachex.get_cluster_info(elasticache)
    read_config_hosts(hosts)
  end
  def read_config_elasticache(_) do
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
  def host_to_atom(hostname, port) do
    String.to_atom("#{hostname}_#{port}")
  end

end
