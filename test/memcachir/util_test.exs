defmodule Memcachir.UtilTest do
  use ExUnit.Case, async: true

  alias Memcachir.Util

  describe "#determine_service_discovery" do
    test "It will default to hosts if no config is given for elasticache" do
      assert Util.determine_service_discovery() == Memcachir.ServiceDiscovery.Hosts
    end
  end

  describe "#parse_hostname" do
    test "It will default hostname without a port to 11211" do
      {host, port} = Util.parse_hostname("localhost")

      assert host == 'localhost'
      assert port == 11_211
    end

    test "It can read a host:port name" do
      {host, port} = Util.parse_hostname("localhost:123")

      assert host == 'localhost'
      assert port == 123
    end

    test "It will raise on invalid hostnames" do
      assert_raise ArgumentError, fn ->
        Util.parse_hostname("host:port:what?")
      end
    end
  end

  describe "#to_server_id" do
    test "It returns a host_port atom" do
      assert Util.to_server_id({"host", 123}) == {:via, Registry, {Memcachir.Registry, :host_123}}
    end
  end
end
