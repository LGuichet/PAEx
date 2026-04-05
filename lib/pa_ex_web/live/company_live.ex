defmodule PAExWeb.CompanyLive.Index do
  @moduledoc "LiveView for listing registered companies."
  use PAExWeb, :live_view

  alias PAEx.Companies
  alias PAEx.Companies.Company

  @impl true
  def mount(_params, _session, socket) do
    companies = Ash.read!(Company, domain: Companies)
    {:ok, assign(socket, companies: companies)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Entreprises</h1>
      <table>
        <thead>
          <tr>
            <th>Nom</th>
            <th>SIREN</th>
            <th>SIRET</th>
            <th>Statut</th>
            <th>Rôle</th>
          </tr>
        </thead>
        <tbody>
          <%= for c <- @companies do %>
            <tr>
              <td>{c.name}</td>
              <td>{c.siren}</td>
              <td>{c.siret}</td>
              <td>{c.status}</td>
              <td>{c.role}</td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end
end
