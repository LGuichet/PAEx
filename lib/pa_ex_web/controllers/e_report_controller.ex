defmodule PAExWeb.EReportController do
  @moduledoc "REST controller for EReport resources."
  use PAExWeb, :controller

  alias PAEx.EReporting
  alias PAEx.EReporting.EReport

  action_fallback PAExWeb.FallbackController

  def index(conn, _params) do
    reports = Ash.read!(EReport, domain: EReporting)
    json(conn, %{data: Enum.map(reports, &report_json/1)})
  end

  def show(conn, %{"id" => id}) do
    report = Ash.get!(EReport, id, domain: EReporting)
    json(conn, %{data: report_json(report)})
  end

  def create(conn, params) do
    with {:ok, report} <-
           Ash.create(EReport, params, action: :create_draft, domain: EReporting) do
      conn
      |> put_status(:created)
      |> json(%{data: report_json(report)})
    end
  end

  def submit(conn, %{"id" => id} = params) do
    report = Ash.get!(EReport, id, domain: EReporting)

    with {:ok, updated} <-
           Ash.update(report, Map.take(params, ["ppf_submission_id"]),
             action: :submit,
             domain: EReporting
           ) do
      json(conn, %{data: report_json(updated)})
    end
  end

  def acknowledge(conn, %{"id" => id} = params) do
    report = Ash.get!(EReport, id, domain: EReporting)

    with {:ok, updated} <-
           Ash.update(report, Map.take(params, ["ppf_acknowledgement_id"]),
             action: :acknowledge_acceptance,
             domain: EReporting
           ) do
      json(conn, %{data: report_json(updated)})
    end
  end

  def reject(conn, %{"id" => id} = params) do
    report = Ash.get!(EReport, id, domain: EReporting)

    with {:ok, updated} <-
           Ash.update(report, Map.take(params, ["rejection_reason"]),
             action: :reject,
             domain: EReporting
           ) do
      json(conn, %{data: report_json(updated)})
    end
  end

  defp report_json(%EReport{} = r) do
    %{
      id: r.id,
      company_id: r.company_id,
      report_type: r.report_type,
      status: r.status,
      period_start: r.period_start,
      period_end: r.period_end,
      total_amount_excl_tax: r.total_amount_excl_tax,
      total_vat_amount: r.total_vat_amount,
      total_amount_incl_tax: r.total_amount_incl_tax,
      transaction_count: r.transaction_count,
      ppf_submission_id: r.ppf_submission_id,
      submitted_at: r.submitted_at,
      ppf_acknowledgement_id: r.ppf_acknowledgement_id,
      rejection_reason: r.rejection_reason
    }
  end
end
