defmodule Memcachir.Worker do

  def start_link(options) do
    Memcache.start_link(options)
  end
end
