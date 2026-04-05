defmodule PAEx.Invoices do
  @moduledoc """
  The Invoices domain handles the full lifecycle of electronic invoices
  (factures électroniques) as required by the French e-invoicing reform.

  ## Invoice lifecycle (cycle de vie)

  ```
  deposee
    │
    ├──[validation OK]──► en_cours_de_traitement
    │                            │
    │                     [routing OK]──► en_cours_d_emission
    │                                          │
    │                                    [delivered]──► emise
    │                                                     │
    │                                        ┌────────────┤
    │                                        │            │
    │                                   [refused]   [accepted]──► mise_en_paiement
    │                                        │                          │
    │                                     refusee               comptabilisee
    │
    ├──[validation KO]──► rejetee
    │
    └──(at any stage before comptabilisee)──► annulee
                                              en_litige
  ```

  ## Supported invoice formats
    * `factur_x` – Factur-X EN 16931 (PDF/A-3 + embedded XML)
    * `ubl`      – Universal Business Language (ISO/IEC 19845)
    * `cii`      – UN/CEFACT Cross Industry Invoice (ISO 19005)
  """
  use Ash.Domain, otp_app: :pa_ex

  resources do
    resource PAEx.Invoices.Invoice
    resource PAEx.Invoices.InvoiceLine
    resource PAEx.Invoices.StatusEvent
  end
end
