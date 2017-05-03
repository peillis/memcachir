defmodule Memcachir.Util do

  @doc """
  Reads the hosts configuration.
  """
  def read_config_hosts(hosts) when is_list(hosts) do
    Enum.map(hosts, fn(host) ->
      {[hostname, port], weight} = build_host_tuple(host)
      {String.to_atom("#{hostname}:#{port}"), [hostname, port], weight}
    end)
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

  defp build_host_tuple(host) when is_binary(host) do
    # assign a default weight of 10
    {parse_hostname(host), 10}
  end
  defp build_host_tuple(host) when is_tuple(host) do
    {parse_hostname(elem(host, 0)), elem(host, 1)}
  end
  defp build_host_tuple(_) do
    raise_error()
  end

  defp parse_hostname(hostname) do
    case String.split(hostname, ":") do
      [hostname, port] ->
        [String.to_charlist(hostname), String.to_integer(port)]
      [hostname] ->
        [String.to_charlist(hostname), 11211]
      _ -> raise_error()
    end
  end

  defp raise_error do
    raise ArgumentError, message: "invalid hosts configuration"
  end

end
