defmodule PAEx.Repo.Migrations.CreateInvoices do
  @moduledoc """
  Creates tables for electronic invoices, their line items, and the status
  audit-trail (status events).
  """
  use Ecto.Migration

  def change do
    create table(:invoices, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false, default: fragment("uuid_generate_v4()")
      add :number, :string, null: false, size: 50
      add :invoice_type, :string, null: false, default: "facture"
      add :format, :string, null: false, default: "factur_x"
      add :status, :string, null: false, default: "deposee"

      add :emitter_id, references(:companies, type: :uuid, on_delete: :restrict), null: false
      add :receiver_id, references(:companies, type: :uuid, on_delete: :restrict), null: false

      add :issue_date, :date, null: false
      add :due_date, :date
      add :delivery_date, :date

      # Amounts in euro cents
      add :amount_excl_tax, :bigint, null: false
      add :amount_vat, :bigint, null: false
      add :amount_incl_tax, :bigint, null: false
      add :currency, :string, null: false, size: 3, default: "EUR"

      add :purchase_order_ref, :string, size: 50
      add :contract_ref, :string, size: 50
      add :payload, :text

      add :ppf_submission_id, :string, size: 100
      add :rejection_reason, :string, size: 1000

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:invoices, [:number, :emitter_id])
    create index(:invoices, [:status])
    create index(:invoices, [:emitter_id])
    create index(:invoices, [:receiver_id])
    create index(:invoices, [:issue_date])
    create index(:invoices, [:due_date])

    create table(:invoice_lines, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false, default: fragment("uuid_generate_v4()")
      add :invoice_id, references(:invoices, type: :uuid, on_delete: :delete_all), null: false
      add :line_number, :integer, null: false
      add :description, :string, null: false, size: 500
      add :product_ref, :string, size: 100
      add :quantity, :decimal, null: false
      add :unit_of_measure, :string, null: false, size: 10, default: "EA"

      # Amounts in euro cents
      add :unit_price, :bigint, null: false
      add :vat_rate, :decimal, null: false
      add :line_amount_excl_tax, :bigint, null: false
      add :line_vat_amount, :bigint, null: false
      add :line_amount_incl_tax, :bigint, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:invoice_lines, [:invoice_id])
    create unique_index(:invoice_lines, [:invoice_id, :line_number])

    create table(:invoice_status_events, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false, default: fragment("uuid_generate_v4()")
      add :invoice_id, references(:invoices, type: :uuid, on_delete: :delete_all), null: false
      add :from_status, :string
      add :to_status, :string, null: false
      add :triggered_by, :string
      add :note, :string, size: 1000
      add :occurred_at, :utc_datetime_usec, null: false
    end

    create index(:invoice_status_events, [:invoice_id])
    create index(:invoice_status_events, [:occurred_at])
  end
end
