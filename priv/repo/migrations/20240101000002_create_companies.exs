defmodule PAEx.Repo.Migrations.CreateCompanies do
  @moduledoc """
  Creates the companies table for legal entities registered on the platform.
  """
  use Ecto.Migration

  def change do
    create table(:companies, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false, default: fragment("uuid_generate_v4()")
      add :name, :string, null: false, size: 255
      add :siren, :string, null: false, size: 9
      add :siret, :string, size: 14
      add :vat_number, :string, size: 20
      add :address_street, :text
      add :address_city, :string, size: 100
      add :address_postal_code, :string, size: 10
      add :address_country, :string, size: 2, default: "FR"
      add :status, :string, null: false, default: "active"
      add :role, :string, null: false, default: "both"
      add :ppf_routing_id, :string, size: 50

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:companies, [:siren])
    create index(:companies, [:status])
    create index(:companies, [:siret])
  end
end
