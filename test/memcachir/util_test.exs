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

end
