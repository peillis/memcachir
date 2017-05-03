defmodule Memcachir.Worker do

  def start_link(hosts) do
    :mcd_cluster.start_link(hosts)
  end
end
