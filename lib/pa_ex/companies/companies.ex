defmodule PAEx.Companies do
  @moduledoc """
  The Companies domain manages the legal entities (entreprises) registered on
  the PAEx platform.

  A company is identified by its SIREN number (9 digits, unique per legal entity)
  and may have one or more establishments identified by their SIRET number (14
  digits: SIREN + 5-digit establishment suffix).  The `ppf_routing_id` field
  stores the identifier in the national PPF directory, which is required to
  route incoming invoices.
  """
  use Ash.Domain, otp_app: :pa_ex

  resources do
    resource PAEx.Companies.Company
  end
end
