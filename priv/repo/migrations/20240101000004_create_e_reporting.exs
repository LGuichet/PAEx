defmodule PAEx.Repo.Migrations.CreateEReporting do
  @moduledoc """
  Creates tables for e-reporting submissions and their individual transaction lines.
  """
  use Ecto.Migration

  def change do
    create table(:e_reports, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false, default: fragment("uuid_generate_v4()")
      add :company_id, references(:companies, type: :uuid, on_delete: :restrict), null: false
      add :report_type, :string, null: false
      add :status, :string, null: false, default: "draft"
      add :period_start, :date, null: false
      add :period_end, :date, null: false

      # Aggregated totals in euro cents
      add :total_amount_excl_tax, :bigint, null: false, default: 0
      add :total_vat_amount, :bigint, null: false, default: 0
      add :total_amount_incl_tax, :bigint, null: false, default: 0
      add :transaction_count, :integer, null: false, default: 0

      add :ppf_submission_id, :string, size: 100
      add :submitted_at, :utc_datetime_usec
      add :ppf_acknowledgement_id, :string, size: 100
      add :rejection_reason, :text

      timestamps(type: :utc_datetime_usec)
    end

    create index(:e_reports, [:company_id])
    create index(:e_reports, [:status])
    create index(:e_reports, [:period_start, :period_end])
    create index(:e_reports, [:report_type])

    create table(:e_report_lines, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false, default: fragment("uuid_generate_v4()")
      add :e_report_id, references(:e_reports, type: :uuid, on_delete: :delete_all), null: false
      add :transaction_date, :date, null: false
      add :transaction_ref, :string, size: 100
      add :customer_country, :string, size: 2
      add :customer_vat_number, :string, size: 20

      # Amounts in euro cents
      add :amount_excl_tax, :bigint, null: false
      add :vat_rate, :decimal, null: false
      add :vat_amount, :bigint, null: false
      add :amount_incl_tax, :bigint, null: false
      add :currency, :string, null: false, size: 3, default: "EUR"

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:e_report_lines, [:e_report_id])
    create index(:e_report_lines, [:transaction_date])
  end
end
