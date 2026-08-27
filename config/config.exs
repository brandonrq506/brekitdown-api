# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :brekitdown, :scopes,
  user: [
    default: true,
    module: Brekitdown.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: Brekitdown.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :flop, repo: Brekitdown.Repo

config :brekitdown,
  ecto_repos: [Brekitdown.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :brekitdown, BrekitdownWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: BrekitdownWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Brekitdown.PubSub,
  live_view: [signing_salt: "JrJdpILf"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Swoosh mailer. Email flows (magic link, email change) are wired but unrouted for now.
# The Local adapter keeps mail in-memory (dev mailbox preview) and needs no external service;
# swap to a real adapter when email is actually sent in production.
config :brekitdown, Brekitdown.Mailer, adapter: Swoosh.Adapters.Local

# Disable Swoosh API client — the Local/Test adapters don't need an HTTP client.
config :swoosh, :api_client, false

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
