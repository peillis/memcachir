use Mix.Config

config :memcachir,
  hosts: ["localhost:11211", "localhost:11212"],
  # hosts: "localhost:11211",
  namespace: "df:1"
