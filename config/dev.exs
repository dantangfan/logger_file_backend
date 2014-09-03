use Mix.Config

config :logger,
  backends: [:console],
  level: :debug,
  format: "$time $metadata[$level] $message\n"

config :logger, :dev_backend,
  level: :error,
  path: "test/logs/error.log",
  format: "DEV $message"
