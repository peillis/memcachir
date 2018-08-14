use Mix.Config

config :memcachir,
  pool: [size: 2],
  health_check: 100

config :memcachir, Memcachir.Pool,
  worker_module: Memcache,
  size: 2

config :elasticachex,
  socket_module: MockSocketModule

config :memcachir, Memcachir.ServiceDiscovery.Elasticache,
  endpoint: "localhost"

config :memcachir, Memcachir.Supervisor,
  max_restarts: 10000