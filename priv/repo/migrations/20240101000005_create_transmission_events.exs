defmodule PAEx.Repo.Migrations.CreateTransmissionEvents do
  @moduledoc """
  Creates the transmission_events table for auditing all messages exchanged
  with the PPF and other external parties.
  """
  use Ecto.Migration

  def change do
    create table(:transmission_events, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false, default: fragment("uuid_generate_v4()")
      add :direction, :string, null: false
      add :counterparty_type, :string, null: false
      add :counterparty_id, :string, size: 200
      add :event_type, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :reference_id, :uuid
      add :reference_type, :string, size: 100
      add :payload_summary, :string, size: 500
      add :http_status_code, :integer
      add :error_message, :text
      add :retry_count, :integer, null: false, default: 0
      add :sent_at, :utc_datetime_usec
      add :acked_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create index(:transmission_events, [:status])
    create index(:transmission_events, [:direction, :status])
    create index(:transmission_events, [:event_type])
    create index(:transmission_events, [:reference_id])
    create index(:transmission_events, [:inserted_at])
  end
end
