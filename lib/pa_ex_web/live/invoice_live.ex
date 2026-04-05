defmodule PAExWeb.InvoiceLive.Index do
  @moduledoc "LiveView for listing and filtering invoices."
  use PAExWeb, :live_view

  alias PAEx.Invoices
  alias PAEx.Invoices.Invoice

  @impl true
  def mount(_params, _session, socket) do
    invoices = Ash.read!(Invoice, domain: Invoices)
    {:ok, assign(socket, invoices: invoices)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Factures électroniques</h1>
      <table>
        <thead>
          <tr>
            <th>Numéro</th>
            <th>Type</th>
            <th>Format</th>
            <th>Statut</th>
            <th>Date d'émission</th>
            <th>Montant TTC</th>
          </tr>
        </thead>
        <tbody>
          <%= for inv <- @invoices do %>
            <tr>
              <td><a href={"/invoices/#{inv.id}"}>{inv.number}</a></td>
              <td>{inv.invoice_type}</td>
              <td>{inv.format}</td>
              <td>{inv.status}</td>
              <td>{inv.issue_date}</td>
              <td>{inv.amount_incl_tax} cts</td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end
end

defmodule PAExWeb.InvoiceLive.Show do
  @moduledoc "LiveView for showing a single invoice."
  use PAExWeb, :live_view

  alias PAEx.Invoices
  alias PAEx.Invoices.Invoice

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    invoice = Ash.get!(Invoice, id, domain: Invoices)
    {:ok, assign(socket, invoice: invoice)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Facture {assigns.invoice.number}</h1>
      <dl>
        <dt>Statut</dt><dd>{@invoice.status}</dd>
        <dt>Format</dt><dd>{@invoice.format}</dd>
        <dt>Date d'émission</dt><dd>{@invoice.issue_date}</dd>
        <dt>Montant HT</dt><dd>{@invoice.amount_excl_tax} cts</dd>
        <dt>TVA</dt><dd>{@invoice.amount_vat} cts</dd>
        <dt>Montant TTC</dt><dd>{@invoice.amount_incl_tax} cts</dd>
      </dl>
      <a href="/invoices">← Retour</a>
    </div>
    """
  end
end
