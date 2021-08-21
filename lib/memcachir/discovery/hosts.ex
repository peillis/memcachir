defmodule Memcachir.ServiceDiscovery.Hosts do
  @moduledoc """
  Service discovery through a hardcoded list.
  """
  @behaviour Herd.Discovery
  alias Memcachir.Util

  def nodes() do
    host_config()
    |> Util.parse_hostname()
  end

  defp host_config() do
    case Application.get_env(:memcachir, :hosts) do
      hosts when is_list(hosts)  -> hosts
      host  when is_binary(host) -> [host]
      _ -> ["localhost"]
    end
  end
end
