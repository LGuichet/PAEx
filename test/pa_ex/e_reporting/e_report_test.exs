defmodule PAEx.EReporting.EReportTest do
  @moduledoc "Unit tests for the EReport resource."
  use PAEx.DataCase, async: true

  alias PAEx.Companies
  alias PAEx.Companies.Company
  alias PAEx.EReporting
  alias PAEx.EReporting.EReport

  setup do
    {:ok, company} =
      Ash.create(
        Company,
        %{name: "Retailer SAS", siren: "333333333", siret: "33333333300033"},
        action: :register,
        domain: Companies
      )

    {:ok, company: company}
  end

  describe "create_draft/1" do
    test "creates a draft B2C e-report", ctx do
      assert {:ok, report} =
               Ash.create(
                 EReport,
                 %{
                   report_type: :b2c,
                   period_start: ~D[2024-01-01],
                   period_end: ~D[2024-01-31],
                   company_id: ctx.company.id
                 },
                 action: :create_draft,
                 domain: EReporting
               )

      assert report.status == :draft
      assert report.report_type == :b2c
      assert report.total_amount_excl_tax == 0
    end

    test "rejects period_end before period_start", ctx do
      assert {:error, %Ash.Error.Invalid{}} =
               Ash.create(
                 EReport,
                 %{
                   report_type: :b2c,
                   period_start: ~D[2024-02-01],
                   period_end: ~D[2024-01-01],
                   company_id: ctx.company.id
                 },
                 action: :create_draft,
                 domain: EReporting
               )
    end
  end

  describe "e-report lifecycle" do
    setup ctx do
      {:ok, report} =
        Ash.create(
          EReport,
          %{
            report_type: :b2c,
            period_start: ~D[2024-01-01],
            period_end: ~D[2024-01-31],
            company_id: ctx.company.id
          },
          action: :create_draft,
          domain: EReporting
        )

      {:ok, report: report}
    end

    test "update totals on draft report", ctx do
      assert {:ok, updated} =
               Ash.update(
                 ctx.report,
                 %{
                   total_amount_excl_tax: 500_000,
                   total_vat_amount: 100_000,
                   total_amount_incl_tax: 600_000,
                   transaction_count: 42
                 },
                 action: :update_totals,
                 domain: EReporting
               )

      assert updated.total_amount_excl_tax == 500_000
      assert updated.transaction_count == 42
    end

    test "submit a draft report", ctx do
      assert {:ok, submitted} =
               Ash.update(
                 ctx.report,
                 %{ppf_submission_id: "PPF-REPORT-001"},
                 action: :submit,
                 domain: EReporting
               )

      assert submitted.status == :submitted
      assert submitted.ppf_submission_id == "PPF-REPORT-001"
      assert not is_nil(submitted.submitted_at)
    end

    test "acknowledge a submitted report", ctx do
      {:ok, submitted} =
        Ash.update(ctx.report, %{ppf_submission_id: "PPF-REPORT-001"},
          action: :submit,
          domain: EReporting
        )

      assert {:ok, accepted} =
               Ash.update(
                 submitted,
                 %{ppf_acknowledgement_id: "ACK-001"},
                 action: :acknowledge_acceptance,
                 domain: EReporting
               )

      assert accepted.status == :accepted
    end

    test "reject a submitted report", ctx do
      {:ok, submitted} =
        Ash.update(ctx.report, %{ppf_submission_id: "PPF-REPORT-001"},
          action: :submit,
          domain: EReporting
        )

      assert {:ok, rejected} =
               Ash.update(
                 submitted,
                 %{rejection_reason: "Données manquantes"},
                 action: :reject,
                 domain: EReporting
               )

      assert rejected.status == :rejected
    end

    test "reopen a rejected report for correction", ctx do
      {:ok, submitted} =
        Ash.update(ctx.report, %{ppf_submission_id: "PPF-REPORT-001"},
          action: :submit,
          domain: EReporting
        )

      {:ok, rejected} =
        Ash.update(submitted, %{rejection_reason: "Données manquantes"},
          action: :reject,
          domain: EReporting
        )

      assert {:ok, reopened} =
               Ash.update(rejected, %{}, action: :reopen, domain: EReporting)

      assert reopened.status == :draft
      assert is_nil(reopened.rejection_reason)
    end

    test "cannot submit an already submitted report", ctx do
      {:ok, submitted} =
        Ash.update(ctx.report, %{ppf_submission_id: "PPF-REPORT-001"},
          action: :submit,
          domain: EReporting
        )

      assert {:error, %Ash.Error.Invalid{}} =
               Ash.update(submitted, %{ppf_submission_id: "PPF-REPORT-002"},
                 action: :submit,
                 domain: EReporting
               )
    end
  end
end
