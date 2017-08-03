defmodule Memcachir.Stats do
  @moduledoc """
  This module provides a nice interface to `:ex_statsd` mixing in some policy stuff like
  a default sample rate and also contains a GenServer that will send Erlang VM level
  statistics regularly.

  This module has been lifted whoesale from db2kafka and maybe should deserve its own
  place in the spotlight; or we could try to push this upstream as part of
  `:ex_statsd`

  Note that ExStatsD opens, for some reason, an UDP socket per stat and therefore is
  not yet fit for high-volume spamming of data. Use sampling to tune it down if
  necessary. There's a PR in the works and we're currently using that version here
  to mitigate the issue, see `mix.exs`.
  """

  @default_sample_rate 1.0
  @gauge_sleep_time_secs 10

  use GenServer

  @spec start_link(String.t) :: GenServer.on_start
  def start_link(name \\ "vm") do
    GenServer.start_link(__MODULE__, name, name: :"stats_#{name}")
  end

  @spec incrementSuccess(String.t, float) :: nil
  def incrementSuccess(metric_name, sample_rate \\ @default_sample_rate) do
    increment(metric_name, ["result:success"], sample_rate)
  end

  @spec incrementFailure(String.t, float) :: nil
  def incrementFailure(metric_name, sample_rate \\ @default_sample_rate) do
    increment(metric_name, ["result:failure"], sample_rate)
  end

  @spec timing(String.t, (() -> ret)) :: ret when ret: any
  def timing(metric_name, fnToTime) do
    ExStatsD.timing(metric_name <> "_msec", fnToTime)
  end

  @spec timer(String.t, number, float) :: nil
  def timer(metric_name, age, sample_rate \\ @default_sample_rate) do
    ExStatsD.timer(age, metric_name <> "_msec", [sample_rate: sample_rate])
  end

  @spec increment(String.t, [String.t], float) :: nil
  def increment(metric_name, tags \\ [], sample_rate \\ @default_sample_rate) do
    ExStatsD.increment(metric_name <> "_count", [sample_rate: sample_rate, tags: tags])
  end

  @spec histogram(integer, String.t) :: nil
  def histogram(amount, metric_name) do
    ExStatsD.histogram(amount, metric_name)
  end

  #  Server side. Run a simple wait loop and emit stats about the Erlang VM every X seconds
  #  https://github.com/Amadiro/erlang-statistics/blob/master/erlang/statistics.erl has
  #  a nice list of stuff you can spam DogStatsD with :)
  def init(name) do
    schedule_work()
    {:ok, name}
  end

  def handle_info(:work, name) do
    send_gauges(name)
    schedule_work()
    {:noreply, name}
  end

  defp schedule_work() do
    Process.send_after(self(), :work, @gauge_sleep_time_secs * 1000)
  end

  defp send_gauges(name) do
    send_erlang_memory_gauges(name)
    send_erlang_process_gauges(name)
  end

  defp send_erlang_memory_gauges(name) do
    :erlang.memory
      |> Enum.each(fn {key, val} -> gauge(name, "memory_" <> Atom.to_string(key), val) end)
  end

  defp send_erlang_process_gauges(name) do
    gauge(name, "run_queue", :erlang.statistics(:run_queue))
    gauge(name, "process_count", :erlang.system_info(:process_count))
    gauge(name, "process_limit", :erlang.system_info(:process_limit))
  end

  defp gauge(name, key, val) do
    ExStatsD.gauge(val, name <> "." <> key, [sample_rate: @default_sample_rate])
  end
end
