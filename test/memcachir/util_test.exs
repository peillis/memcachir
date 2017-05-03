defmodule Memcachir.UtilTest do
  use ExUnit.Case

  import Memcachir.Util

  test "read hosts configuration" do
    assert read_config_hosts("localhost") ==
      [{:"localhost:11211", ['localhost', 11211], 10}]
    assert read_config_hosts(["localhost:1", "other:2"]) ==
      [{:"localhost:1", ['localhost', 1], 10}, {:"other:2", ['other', 2], 10}]
    assert read_config_hosts([{"localhost:1", 20}, {"other:2", 30}]) ==
      [{:"localhost:1", ['localhost', 1], 20}, {:"other:2", ['other', 2], 30}]
  end
  
end
