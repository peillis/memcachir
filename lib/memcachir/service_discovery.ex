defmodule Memcachir.ServiceDiscovery do
  @moduledoc """
  Entrypoint to the configured service discovery mechanism
  """

  defmodule API do
    @moduledoc """
    Behaviour for handling memcached service discovery
    """

    @doc """
    Fetch the nodes for a given cluster as host, port pairs
    """
    @callback nodes() :: [{binary, integer}]
  end

  alias Memcachir.Util

  @doc """
  Uses the configured service discovery mechanism to get the current cluster
  """
  def nodes() do
    service_discovery = Util.determine_service_discovery()
    service_discovery.nodes()
  end
end
