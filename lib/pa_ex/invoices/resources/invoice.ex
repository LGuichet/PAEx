defmodule PAEx.Invoices.Invoice do
  @moduledoc """
  An electronic invoice (facture électronique) exchanged between two companies
  through the PAEx platform.

  ## Statuses
    * `deposee`               – submitted to the platform, pending validation
    * `en_cours_de_traitement`– passed format validation, being processed
    * `rejetee`               – rejected by the platform (format/content error)
    * `en_cours_d_emission`   – routed to recipient's PDP, pending delivery ACK
    * `emise`                 – delivered to recipient's platform
    * `refusee`               – refused by the recipient
    * `acceptee`              – accepted by the recipient
    * `mise_en_paiement`      – payment initiated
    * `comptabilisee`         – accounted in recipient's system
    * `en_litige`             – under dispute
    * `annulee`               – cancelled

  ## Formats
    * `factur_x` – Factur-X (PDF/A-3 + embedded EN 16931 XML)
    * `ubl`      – Universal Business Language
    * `cii`      – Cross Industry Invoice
  """
  use Ash.Resource,
    otp_app: :pa_ex,
    domain: PAEx.Invoices,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  @statuses [
    :deposee,
    :en_cours_de_traitement,
    :rejetee,
    :en_cours_d_emission,
    :emise,
    :refusee,
    :acceptee,
    :mise_en_paiement,
    :comptabilisee,
    :en_litige,
    :annulee
  ]

  @formats [:factur_x, :ubl, :cii]

  @invoice_types [:facture, :avoir, :facture_rectificative]

  postgres do
    table "invoices"
    repo PAEx.Repo
  end

  attributes do
    uuid_primary_key :id

    # Human-readable invoice number assigned by the emitter
    attribute :number, :string do
      allow_nil? false
      public? true
      constraints max_length: 50
    end

    attribute :invoice_type, :atom do
      constraints one_of: @invoice_types
      default :facture
      allow_nil? false
      public? true
    end

    attribute :format, :atom do
      constraints one_of: @formats
      default :factur_x
      allow_nil? false
      public? true
    end

    attribute :status, :atom do
      constraints one_of: @statuses
      default :deposee
      allow_nil? false
      public? true
    end

    attribute :issue_date, :date do
      allow_nil? false
      public? true
    end

    attribute :due_date, :date do
      allow_nil? true
      public? true
    end

    attribute :delivery_date, :date do
      allow_nil? true
      public? true
    end

    # Monetary amounts (in EUR cents to avoid floating-point issues)
    attribute :amount_excl_tax, :integer do
      allow_nil? false
      public? true
      description "Total amount excluding taxes, in euro cents."
    end

    attribute :amount_vat, :integer do
      allow_nil? false
      public? true
      description "Total VAT amount, in euro cents."
    end

    attribute :amount_incl_tax, :integer do
      allow_nil? false
      public? true
      description "Total amount including taxes, in euro cents."
    end

    attribute :currency, :string do
      allow_nil? false
      public? true
      default "EUR"
      constraints min_length: 3, max_length: 3
    end

    # Purchase order reference (if any)
    attribute :purchase_order_ref, :string do
      allow_nil? true
      public? true
      constraints max_length: 50
    end

    # Contract reference (if any)
    attribute :contract_ref, :string do
      allow_nil? true
      public? true
      constraints max_length: 50
    end

    # Raw invoice payload (XML content for UBL/CII or base64-encoded PDF for Factur-X)
    attribute :payload, :string do
      allow_nil? true
      sensitive? false
      public? false
    end

    # Routing metadata
    attribute :ppf_submission_id, :string do
      allow_nil? true
      public? true
      description "Identifier assigned by the PPF upon successful submission."
    end

    attribute :rejection_reason, :string do
      allow_nil? true
      public? true
      constraints max_length: 1000
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :emitter, PAEx.Companies.Company do
      allow_nil? false
      public? true
    end

    belongs_to :receiver, PAEx.Companies.Company do
      allow_nil? false
      public? true
    end

    has_many :lines, PAEx.Invoices.InvoiceLine do
      destination_attribute :invoice_id
    end

    has_many :status_events, PAEx.Invoices.StatusEvent do
      destination_attribute :invoice_id
    end
  end

  identities do
    identity :unique_number_per_emitter, [:number, :emitter_id]
  end

  validations do
    validate compare(:amount_excl_tax, greater_than_or_equal_to: 0) do
      message "cannot be negative"
    end

    validate compare(:amount_vat, greater_than_or_equal_to: 0) do
      message "cannot be negative"
    end

    validate compare(:amount_incl_tax, greater_than_or_equal_to: 0) do
      message "cannot be negative"
    end

    validate compare(:due_date, greater_than_or_equal_to: :issue_date) do
      where present(:due_date)
      message "must be on or after the issue date"
    end
  end

  actions do
    defaults [:read, :destroy]

    create :submit do
      description "Submit a new invoice to the platform (initial deposit)."
      accept [
        :number,
        :invoice_type,
        :format,
        :issue_date,
        :due_date,
        :delivery_date,
        :amount_excl_tax,
        :amount_vat,
        :amount_incl_tax,
        :currency,
        :purchase_order_ref,
        :contract_ref,
        :payload,
        :emitter_id,
        :receiver_id
      ]
    end

    # --- Lifecycle transitions ---

    update :start_processing do
      description "Mark the invoice as being processed after format validation."
      accept []

      validate attribute_equals(:status, :deposee) do
        message "Invoice must be in 'deposee' status to start processing"
      end

      change set_attribute(:status, :en_cours_de_traitement)
    end

    update :reject do
      description "Reject the invoice due to a validation or format error."
      accept [:rejection_reason]

      validate attribute_in(:status, [:deposee, :en_cours_de_traitement]) do
        message "Invoice must be in 'deposee' or 'en_cours_de_traitement' status to be rejected"
      end

      change set_attribute(:status, :rejetee)
    end

    update :start_emission do
      description "Begin routing the invoice to the recipient's platform."
      accept []

      validate attribute_equals(:status, :en_cours_de_traitement) do
        message "Invoice must be 'en_cours_de_traitement' to start emission"
      end

      change set_attribute(:status, :en_cours_d_emission)
    end

    update :mark_emitted do
      description "Confirm that the invoice was delivered to the recipient's platform."
      accept [:ppf_submission_id]

      validate attribute_equals(:status, :en_cours_d_emission) do
        message "Invoice must be 'en_cours_d_emission' to be marked as emitted"
      end

      change set_attribute(:status, :emise)
    end

    update :refuse do
      description "Record that the recipient refused the invoice."
      accept [:rejection_reason]

      validate attribute_equals(:status, :emise) do
        message "Invoice must be 'emise' to be refused"
      end

      change set_attribute(:status, :refusee)
    end

    update :accept do
      description "Record that the recipient accepted the invoice."
      accept []

      validate attribute_equals(:status, :emise) do
        message "Invoice must be 'emise' to be accepted"
      end

      change set_attribute(:status, :acceptee)
    end

    update :initiate_payment do
      description "Record that payment has been initiated by the recipient."
      accept []

      validate attribute_equals(:status, :acceptee) do
        message "Invoice must be 'acceptee' before payment can be initiated"
      end

      change set_attribute(:status, :mise_en_paiement)
    end

    update :mark_accounted do
      description "Mark the invoice as accounted in the recipient's system."
      accept []

      validate attribute_equals(:status, :mise_en_paiement) do
        message "Invoice must be 'mise_en_paiement' before it can be accounted"
      end

      change set_attribute(:status, :comptabilisee)
    end

    update :raise_dispute do
      description "Mark the invoice as under dispute."
      accept []

      validate attribute_in(:status, [:emise, :acceptee, :mise_en_paiement]) do
        message "Invoice must be emised, accepted, or in payment to be disputed"
      end

      change set_attribute(:status, :en_litige)
    end

    update :cancel do
      description "Cancel the invoice. Only allowed before it has been accounted."
      accept []

      validate attribute_not_in(:status, [:comptabilisee, :annulee]) do
        message "Invoice cannot be cancelled once it has been accounted"
      end

      change set_attribute(:status, :annulee)
    end

    read :by_status do
      description "List invoices with a given status."
      argument :status, :atom, allow_nil?: false
      filter expr(status == ^arg(:status))
    end

    read :for_emitter do
      description "List invoices emitted by a given company."
      argument :emitter_id, :uuid, allow_nil?: false
      filter expr(emitter_id == ^arg(:emitter_id))
    end

    read :for_receiver do
      description "List invoices addressed to a given company."
      argument :receiver_id, :uuid, allow_nil?: false
      filter expr(receiver_id == ^arg(:receiver_id))
    end
  end

  calculations do
    calculate :amount_excl_tax_eur, :decimal, expr(amount_excl_tax / 100.0)
    calculate :amount_vat_eur, :decimal, expr(amount_vat / 100.0)
    calculate :amount_incl_tax_eur, :decimal, expr(amount_incl_tax / 100.0)

    calculate :overdue?, :boolean,
              expr(
                not is_nil(due_date) and due_date < fragment("current_date") and
                  status not in [:comptabilisee, :annulee, :refusee]
              )
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    policy action(:submit) do
      authorize_if actor_attribute_equals(:role, :admin)
      authorize_if actor_attribute_equals(:role, :operator)
      authorize_if actor_attribute_equals(:role, :api_client)
    end

    policy action_type(:update) do
      authorize_if actor_attribute_equals(:role, :admin)
      authorize_if actor_attribute_equals(:role, :operator)
    end

    policy action_type(:destroy) do
      authorize_if actor_attribute_equals(:role, :admin)
    end
  end
end
