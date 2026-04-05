defmodule PAExWeb.EReportLive.Index do
  @moduledoc "LiveView for listing e-reports."
  use PAExWeb, :live_view

  alias PAEx.EReporting
  alias PAEx.EReporting.EReport

  @impl true
  def mount(_params, _session, socket) do
    reports = Ash.read!(EReport, domain: EReporting)
    {:ok, assign(socket, reports: reports)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>E-Reporting</h1>
      <table>
        <thead>
          <tr>
            <th>Type</th>
            <th>Statut</th>
            <th>Période début</th>
            <th>Période fin</th>
            <th>Transactions</th>
            <th>Montant TTC</th>
          </tr>
        </thead>
        <tbody>
          <%= for r <- @reports do %>
            <tr>
              <td>{r.report_type}</td>
              <td>{r.status}</td>
              <td>{r.period_start}</td>
              <td>{r.period_end}</td>
              <td>{r.transaction_count}</td>
              <td>{r.total_amount_incl_tax} cts</td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end
end
