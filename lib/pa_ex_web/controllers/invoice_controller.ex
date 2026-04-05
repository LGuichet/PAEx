defmodule PAExWeb.InvoiceController do
  @moduledoc "REST controller for Invoice resources and lifecycle transitions."
  use PAExWeb, :controller

  alias PAEx.Invoices
  alias PAEx.Invoices.Invoice

  action_fallback PAExWeb.FallbackController

  def index(conn, params) do
    query =
      Invoice
      |> Ash.Query.new()
      |> maybe_filter_by_status(params)

    invoices = Ash.read!(query, domain: Invoices)
    json(conn, %{data: Enum.map(invoices, &invoice_json/1)})
  end

  def show(conn, %{"id" => id}) do
    invoice = Ash.get!(Invoice, id, domain: Invoices)
    json(conn, %{data: invoice_json(invoice)})
  end

  def create(conn, params) do
    with {:ok, invoice} <-
           Ash.create(Invoice, params, action: :submit, domain: Invoices) do
      conn
      |> put_status(:created)
      |> json(%{data: invoice_json(invoice)})
    end
  end

  # Lifecycle transition helpers

  def start_processing(conn, %{"id" => id}) do
    lifecycle_action(conn, id, :start_processing, %{})
  end

  def reject(conn, %{"id" => id} = params) do
    lifecycle_action(conn, id, :reject, Map.take(params, ["rejection_reason"]))
  end

  def start_emission(conn, %{"id" => id}) do
    lifecycle_action(conn, id, :start_emission, %{})
  end

  def mark_emitted(conn, %{"id" => id} = params) do
    lifecycle_action(conn, id, :mark_emitted, Map.take(params, ["ppf_submission_id"]))
  end

  def refuse(conn, %{"id" => id} = params) do
    lifecycle_action(conn, id, :refuse, Map.take(params, ["rejection_reason"]))
  end

  def accept(conn, %{"id" => id}) do
    lifecycle_action(conn, id, :accept, %{})
  end

  def initiate_payment(conn, %{"id" => id}) do
    lifecycle_action(conn, id, :initiate_payment, %{})
  end

  def mark_accounted(conn, %{"id" => id}) do
    lifecycle_action(conn, id, :mark_accounted, %{})
  end

  def raise_dispute(conn, %{"id" => id}) do
    lifecycle_action(conn, id, :raise_dispute, %{})
  end

  def cancel(conn, %{"id" => id}) do
    lifecycle_action(conn, id, :cancel, %{})
  end

  # ── Private helpers ──────────────────────────────────────────────────────────

  defp lifecycle_action(conn, id, action, params) do
    invoice = Ash.get!(Invoice, id, domain: Invoices)

    with {:ok, updated} <- Ash.update(invoice, params, action: action, domain: Invoices) do
      json(conn, %{data: invoice_json(updated)})
    end
  end

  defp maybe_filter_by_status(query, %{"status" => status}) do
    Ash.Query.filter(query, status == ^String.to_existing_atom(status))
  end

  defp maybe_filter_by_status(query, _params), do: query

  defp invoice_json(%Invoice{} = inv) do
    %{
      id: inv.id,
      number: inv.number,
      invoice_type: inv.invoice_type,
      format: inv.format,
      status: inv.status,
      emitter_id: inv.emitter_id,
      receiver_id: inv.receiver_id,
      issue_date: inv.issue_date,
      due_date: inv.due_date,
      delivery_date: inv.delivery_date,
      amount_excl_tax: inv.amount_excl_tax,
      amount_vat: inv.amount_vat,
      amount_incl_tax: inv.amount_incl_tax,
      currency: inv.currency,
      purchase_order_ref: inv.purchase_order_ref,
      contract_ref: inv.contract_ref,
      ppf_submission_id: inv.ppf_submission_id,
      rejection_reason: inv.rejection_reason
    }
  end
end
