defmodule Memcachir.ServiceDiscovery.ElasticacheTest do
  use ExUnit.Case, async: false
  alias Memcachir.ServiceDiscovery.Elasticache

  test "read elasticache configuration" do
    MockSocketModule.update(["localhost|localhost|11211"])
    assert Elasticache.nodes == [{'localhost', 11_211}]
  end
end