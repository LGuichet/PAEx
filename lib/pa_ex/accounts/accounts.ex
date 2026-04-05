defmodule PAEx.Accounts do
  @moduledoc """
  The Accounts domain manages users and authentication tokens for the PAEx platform.

  Users can hold different roles within the system:

    * `:admin` — platform administrators with full access
    * `:operator` — staff who manage invoices and e-reporting on behalf of companies
    * `:api_client` — machine-to-machine clients (PDPs, ERPs, etc.)
  """
  use Ash.Domain, otp_app: :pa_ex

  resources do
    resource PAEx.Accounts.User
    resource PAEx.Accounts.Token
  end
end
