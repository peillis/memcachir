# Memcachir

[![Build Status](https://secure.travis-ci.org/peillis/memcachir.png)](http://travis-ci.org/peillis/memcachir)

Memcached client for Elixir

## Installation

```elixir
defp deps() do
  ...
  {:memcachir, "~> 3.0"},
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

## Example

```elixir
iex> Memcachir.set("hello", "world")
{:ok}
iex> Memcachir.get("hello")
{:ok, "world"}
```
