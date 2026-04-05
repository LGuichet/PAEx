defmodule PAEx.Application do
  @moduledoc """
  OTP Application entry point for PAEx – Plateforme Agréée Elixir.

  Starts the supervision tree including the database repo, Phoenix endpoint,
  and any background workers required for e-invoicing and e-reporting.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PAExWeb.Telemetry,
      PAEx.Repo,
      {DNSCluster, query: Application.get_env(:pa_ex, :dns_cluster_query, :ignore)},
      {Phoenix.PubSub, name: PAEx.PubSub},
      PAExWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: PAEx.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PAExWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
