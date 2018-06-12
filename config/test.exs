use Mix.Config

config :memcachir,
  health_check: 100

config :elasticachex,
  socket_module: MockSocketModule
