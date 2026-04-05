defmodule PAExWeb.CompanyController do
  @moduledoc "REST controller for Company resources."
  use PAExWeb, :controller

  alias PAEx.Companies
  alias PAEx.Companies.Company

  action_fallback PAExWeb.FallbackController

  def index(conn, _params) do
    companies =
      Company
      |> Ash.Query.new()
      |> Ash.read!(domain: Companies)

    json(conn, %{data: Enum.map(companies, &company_json/1)})
  end

  def show(conn, %{"id" => id}) do
    company =
      Company
      |> Ash.get!(id, domain: Companies)

    json(conn, %{data: company_json(company)})
  end

  def create(conn, params) do
    with {:ok, company} <-
           Ash.create(Company, params, action: :register, domain: Companies) do
      conn
      |> put_status(:created)
      |> json(%{data: company_json(company)})
    end
  end

  def update(conn, %{"id" => id} = params) do
    company = Ash.get!(Company, id, domain: Companies)

    with {:ok, updated} <-
           Ash.update(company, params, action: :update_details, domain: Companies) do
      json(conn, %{data: company_json(updated)})
    end
  end

  defp company_json(%Company{} = c) do
    %{
      id: c.id,
      name: c.name,
      siren: c.siren,
      siret: c.siret,
      vat_number: c.vat_number,
      address_street: c.address_street,
      address_city: c.address_city,
      address_postal_code: c.address_postal_code,
      address_country: c.address_country,
      status: c.status,
      role: c.role,
      ppf_routing_id: c.ppf_routing_id
    }
  end
end
