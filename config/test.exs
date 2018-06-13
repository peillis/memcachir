use Mix.Config

config :memcachir,
  pool: [size: 2],
  health_check: 100

config :elasticachex,
  socket_module: MockSocketModule
