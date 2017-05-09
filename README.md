# Memcachir

[![Build Status](https://secure.travis-ci.org/peillis/memcachir.png)](http://travis-ci.org/peillis/memcachir)

Memcached client for Elixir.

It's basically an elixir wrapper of the [mero](https://github.com/AdRoll/mero)
Erlang library.

## Installation

```elixir
defp deps() do
  ...
  {:memcachir, "~> 2.0.0"},
  ...
end

defp application() do
  [applications: [:logger, :memcachir, ...]]
end
```

```elixir
config :memcachir,
  hosts: "localhost",
  # memcached options
  ttl: 0,
  namespace: nil

config :mero,  # mero config is required
  workers_per_shard: 1,
  initial_connections_per_pool: 20,
  min_free_connections_per_pool: 10,
  max_connections_per_pool: 50,
  timeout_read: 30,
  timeout_write: 5000,
  write_retries: 3,
  expiration_time: 86400,  # One day
  connection_unused_max_time: 300000,
  expiration_interval: 300000,
  max_connection_delay_time: 5000,
  stat_event_callback: {:mero_stat, :noop}
```

The `hosts` config allows multiple variants:

```elixir
hosts: "localhost:11212"  # specify port
hosts: ["host1", "host2", "host3:11212"]  # cluster of servers
```

## Example

```elixir
iex> Memcachir.set("hello", "world")
{:ok, "world"}
iex> Memcachir.get("hello")
{:ok, "world"}
```
