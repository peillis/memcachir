defmodule Memcachir.ServiceDiscovery.HostsTest do
  use ExUnit.Case, async: true
  alias Memcachir.ServiceDiscovery.Hosts

  test "read hosts configuration" do
    assert Hosts.nodes() == [{'localhost', 11_211}]
  end
end