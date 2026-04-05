defmodule PAExWeb.DashboardLive do
  @moduledoc "Platform dashboard showing key metrics."
  use PAExWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>PAEx — Plateforme Agréée Elixir</h1>
      <p>Tableau de bord de la plateforme de facturation électronique.</p>
      <ul>
        <li><a href="/invoices">Factures</a></li>
        <li><a href="/e_reports">E-Reporting</a></li>
        <li><a href="/companies">Entreprises</a></li>
      </ul>
    </div>
    """
  end
end
