use Mix.Config

config :mero,
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

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
