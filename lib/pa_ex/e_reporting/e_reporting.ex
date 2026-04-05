defmodule PAEx.EReporting do
  @moduledoc """
  The EReporting domain manages periodic e-reporting obligations as defined by
  the French DGFiP for the mandatory e-invoicing reform.

  E-reporting covers transaction flows that are **not** subject to e-invoicing:
    * `b2c`              – B2C (business-to-consumer) transactions
    * `b2b_international`– cross-border B2B transactions with non-French counterparts
    * `payment`          – payment data transmission

  Reports are grouped into **periods** (a calendar month or week depending on
  the company's reporting frequency) and transmitted to the PPF.
  """
  use Ash.Domain, otp_app: :pa_ex

  resources do
    resource PAEx.EReporting.EReport
    resource PAEx.EReporting.EReportLine
  end
end
