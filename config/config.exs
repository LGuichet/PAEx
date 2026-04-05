import Config

# Configure Ash domains
config :pa_ex,
  ash_domains: [
    PAEx.Accounts,
    PAEx.Companies,
    PAEx.Invoices,
    PAEx.EReporting,
    PAEx.Transmission
  ]

# Ecto repos
config :pa_ex,
  ecto_repos: [PAEx.Repo]

config :pa_ex, PAEx.Repo,
  migration_primary_key: [type: :uuid],
  migration_timestamps: [type: :utc_datetime_usec]

# Phoenix endpoint
config :pa_ex, PAExWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: PAExWeb.ErrorHTML, json: PAExWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PAEx.PubSub,
  live_view: [signing_salt: "pa_ex_lv_salt"]

# Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :domain]

# Phoenix
config :phoenix, :json_library, Jason

# AshJsonApi
config :ash_json_api,
  include_nil_values?: false

import_config "#{config_env()}.exs"
