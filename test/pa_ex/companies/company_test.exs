defmodule PAEx.Companies.CompanyTest do
  @moduledoc "Unit tests for the Company resource."
  use PAEx.DataCase, async: true

  alias PAEx.Companies
  alias PAEx.Companies.Company

  @valid_attrs %{
    name: "Test Corp SAS",
    siren: "123456789",
    siret: "12345678900012",
    vat_number: "FR12123456789",
    address_street: "1 Rue Test",
    address_city: "Paris",
    address_postal_code: "75001",
    address_country: "FR",
    role: :both
  }

  describe "register/1" do
    test "creates a company with valid attributes" do
      assert {:ok, company} =
               Ash.create(Company, @valid_attrs, action: :register, domain: Companies)

      assert company.name == "Test Corp SAS"
      assert company.siren == "123456789"
      assert company.siret == "12345678900012"
      assert company.status == :active
      assert company.address_country == "FR"
    end

    test "enforces unique SIREN" do
      {:ok, _} = Ash.create(Company, @valid_attrs, action: :register, domain: Companies)

      assert {:error, %Ash.Error.Invalid{}} =
               Ash.create(
                 Company,
                 Map.put(@valid_attrs, :siret, "12345678900099"),
                 action: :register,
                 domain: Companies
               )
    end

    test "rejects invalid SIREN format" do
      invalid = Map.put(@valid_attrs, :siren, "12345")

      assert {:error, %Ash.Error.Invalid{}} =
               Ash.create(Company, invalid, action: :register, domain: Companies)
    end

    test "rejects invalid SIRET format" do
      invalid = Map.put(@valid_attrs, :siret, "1234567890")

      assert {:error, %Ash.Error.Invalid{}} =
               Ash.create(Company, invalid, action: :register, domain: Companies)
    end

    test "allows nil SIRET" do
      attrs = Map.delete(@valid_attrs, :siret)

      assert {:ok, company} = Ash.create(Company, attrs, action: :register, domain: Companies)
      assert is_nil(company.siret)
    end
  end

  describe "suspend/1" do
    test "suspends an active company" do
      {:ok, company} = Ash.create(Company, @valid_attrs, action: :register, domain: Companies)

      assert {:ok, suspended} = Ash.update(company, %{}, action: :suspend, domain: Companies)
      assert suspended.status == :suspended
    end
  end

  describe "reactivate/1" do
    test "reactivates a suspended company" do
      {:ok, company} = Ash.create(Company, @valid_attrs, action: :register, domain: Companies)
      {:ok, suspended} = Ash.update(company, %{}, action: :suspend, domain: Companies)

      assert {:ok, active} = Ash.update(suspended, %{}, action: :reactivate, domain: Companies)
      assert active.status == :active
    end
  end

  describe "close/1" do
    test "closes a company" do
      {:ok, company} = Ash.create(Company, @valid_attrs, action: :register, domain: Companies)

      assert {:ok, closed} = Ash.update(company, %{}, action: :close, domain: Companies)
      assert closed.status == :closed
    end
  end

  describe "by_siren/1" do
    test "finds a company by SIREN" do
      {:ok, _company} = Ash.create(Company, @valid_attrs, action: :register, domain: Companies)

      assert {:ok, [found]} =
               Ash.read(Company, action: :by_siren, domain: Companies,
                 arguments: %{siren: "123456789"})

      assert found.siren == "123456789"
    end
  end
end
