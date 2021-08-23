# Memcachir

[![Build Status](https://secure.travis-ci.org/peillis/memcachir.png)](http://travis-ci.org/peillis/memcachir)
[![Module Version](https://img.shields.io/hexpm/v/memcachir.svg)](https://hex.pm/packages/memcachir)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/memcachir/)
[![Total Download](https://img.shields.io/hexpm/dt/memcachir.svg)](https://hex.pm/packages/memcachir)
[![License](https://img.shields.io/hexpm/l/memcachir.svg)](https://github.com/peillis/memcachir/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/peillis/memcachir.svg)](https://github.com/peillis/memcachir/commits/master)

Memcached client for Elixir. It supports clusters and AWS Elasticache.

## Installation

```elixir
defp deps() do
  ...
  {:memcachir, "~> 3.3"},
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

Example with ttl (in seconds)
```elixir
iex> Memcachir.set("hello", "world", ttl: 5)
{:ok}
iex> Memcachir.get("hello")
{:ok, "world"}
iex> :timer.sleep(5001)
:ok
iex> Memcachir.get("hello")
{:error, "Key not found"}
```

## Copyright and License

Copyright (c) 2017 Enrique Martinez

This library licensed under the [MIT license](./LICENSE.md).
