# Memcachir

[![Build Status](https://secure.travis-ci.org/peillis/memcachir.png)](http://travis-ci.org/peillis/memcachir)

Memcached client for Elixir. It supports clusters and AWS Elasticache.

## Installation

```elixir
defp deps() do
  ...
  {:memcachir, "~> 3.2"},
  ...
end

defp application() do
  [applications: [:logger, :memcachir, ...]]
end
```

```elixir
config :memcachir,
  hosts: "localhost"
```

The `hosts` config allows multiple variants:

```elixir
hosts: "localhost:11212"  # specify port
hosts: ["host1", "host2", "host3:11212"]  # cluster of servers
hosts: [{"host1", 10}, {"host2", 30}]  # cluster with weights
```

Alternatively you can use the elasticache config option:

```elixir
config :memcachir,
  elasticache: "your-config-endpoint.cache.amazonaws.com"
```

## Configuration

Complete configuration options with default values:

```elixir
config :memcachir,
  hosts: "localhost",
  # memcached options
  ttl: 0,
  namespace: nil,
  # connection pool options
  pool: [
    strategy: :lifo,
    size: 10,
    max_overflow: 10]
```

## Service Discovery

If you don't want to use the built in service discovery methods (host list, elasticache), you can implement the `Herd.Discovery` behavior, which just has a single `nodes/0` callback.  Then configure it in with:

```elixir
config :memcachir, :service_discovery, MyMemcacheServiceDiscovery
```

(NB you'll need to delete the `config :memcachir, :hosts` and `config :memcachir, :elasticache` entries to use a custom service discovery module)

## Example

```elixir
iex> Memcachir.set("hello", "world")
{:ok}
iex> Memcachir.get("hello")
{:ok, "world"}
```
