import Config

config :pa_ex, PAEx.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "pa_ex_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :pa_ex, PAExWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_at_least_64_bytes_long_replace_in_production_00",
  server: false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime
