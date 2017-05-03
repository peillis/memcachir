defmodule Memcachir do
  @moduledoc """
  Module with a friendly API for memcached servers.

  It provides connection pooling, and cluster support.

  ## Example

      {:ok, "world"} = Memcachir.set("hello", "world")
      {:ok, "world"} = Memcachir.get("hello")

  """
  use Application
  use Memcachir.Api

  alias Memcachir.Util

  @doc """
  Starts application.
  """
  def start(_type, _args) do
    hosts = Util.read_config_hosts(Application.get_env(:memcachir, :hosts))
    pool_options = Application.get_env(:memcachir, :pool, [])

    Memcachir.Supervisor.start_link(hosts, pool_options)
  end

end
