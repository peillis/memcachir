defmodule Memcachir.UtilTest do
  use ExUnit.Case

  import Memcachir.Util

  test "read hosts configuration" do
    assert read_config_hosts("localhost") ==
      [{'localhost', 11211}]
    assert read_config_hosts("localhost:11212") ==
      [{'localhost', 11212}]
    assert read_config_hosts(["localhost:1", "other:2"]) ==
      [{'localhost', 1}, {'other', 2}]
  end

  test "read elasticache configuration" do
    defmodule MockElasticache do
      def get_cluster_info('invalid', _port) do
        raise "unable to talk to ElastiCache"
      end

      def get_cluster_info(host, port) do
        {:ok, ["#{host}:#{port}"], "1.4.14"}
      end
    end

    assert read_config_elasticache("localhost", MockElasticache) ==
      [{'localhost', 11211}]
    assert read_config_elasticache("localhost:11211", MockElasticache) ==
      [{'localhost', 11211}]
    assert read_config_elasticache("other:80", MockElasticache) ==
      [{'other', 80}]
    assert read_config_elasticache("invalid", MockElasticache) ==
      []
  end
end
