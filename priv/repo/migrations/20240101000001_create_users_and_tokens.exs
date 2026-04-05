defmodule PAEx.Repo.Migrations.CreateUsersAndTokens do
  @moduledoc """
  Initial migration: users and authentication tokens.
  """
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"", "SELECT 1"
    execute "CREATE EXTENSION IF NOT EXISTS \"citext\"", "SELECT 1"

    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false, default: fragment("uuid_generate_v4()")
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :role, :string, null: false, default: "operator"
      add :confirmed_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:users, [:email])

    create table(:tokens, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false, default: fragment("uuid_generate_v4()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :token, :string, null: false
      add :context, :string, null: false
      add :sent_to, :string
      add :expires_at, :utc_datetime_usec, null: false

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:tokens, [:user_id])
    create index(:tokens, [:context, :token])
  end
end
