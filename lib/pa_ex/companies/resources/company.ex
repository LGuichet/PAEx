defmodule PAEx.Companies.Company do
  @moduledoc """
  A legal entity (entreprise / établissement) registered on the PAEx platform.

  ## Identifiers
    * `siren`  – 9-digit French company identifier (registre du commerce)
    * `siret`  – 14-digit establishment identifier (SIREN + NIC)
    * `vat_number` – intra-EU VAT number (e.g. `FR12345678901`)

  ## Status
    * `:active`    – the company can emit and receive invoices
    * `:suspended` – operations are temporarily blocked
    * `:closed`    – the company has been deregistered

  ## Role on the platform
    * `:emitter`  – the company only emits invoices (vendeur / fournisseur)
    * `:receiver` – the company only receives invoices (acheteur / client)
    * `:both`     – the company both emits and receives invoices
  """
  use Ash.Resource,
    otp_app: :pa_ex,
    domain: PAEx.Companies,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "companies"
    repo PAEx.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
      constraints max_length: 255
    end

    # SIREN: 9 digits
    attribute :siren, :string do
      allow_nil? false
      public? true
      constraints min_length: 9, max_length: 9, match: ~r/^\d{9}$/
    end

    # SIRET: SIREN (9) + NIC (5) = 14 digits
    attribute :siret, :string do
      allow_nil? true
      public? true
      constraints min_length: 14, max_length: 14, match: ~r/^\d{14}$/
    end

    attribute :vat_number, :string do
      allow_nil? true
      public? true
      constraints max_length: 20
    end

    # Address fields (required by French e-invoicing specs)
    attribute :address_street, :string do
      allow_nil? true
      public? true
    end

    attribute :address_city, :string do
      allow_nil? true
      public? true
      constraints max_length: 100
    end

    attribute :address_postal_code, :string do
      allow_nil? true
      public? true
      constraints max_length: 10
    end

    attribute :address_country, :string do
      allow_nil? true
      public? true
      constraints min_length: 2, max_length: 2
      default "FR"
    end

    attribute :status, :atom do
      constraints one_of: [:active, :suspended, :closed]
      default :active
      allow_nil? false
      public? true
    end

    attribute :role, :atom do
      constraints one_of: [:emitter, :receiver, :both]
      default :both
      allow_nil? false
      public? true
    end

    # Identifier in the PPF national directory for routing incoming invoices.
    # For PDPs, this is the SIRET or a specific routing code assigned by the PPF.
    attribute :ppf_routing_id, :string do
      allow_nil? true
      public? true
      constraints max_length: 50
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  identities do
    identity :unique_siren, [:siren]
  end

  relationships do
    has_many :emitted_invoices, PAEx.Invoices.Invoice do
      source_attribute :id
      destination_attribute :emitter_id
    end

    has_many :received_invoices, PAEx.Invoices.Invoice do
      source_attribute :id
      destination_attribute :receiver_id
    end
  end

  validations do
    # Luhn-like SIREN check is handled at the service layer; here we validate format only.
    validate match(:siren, ~r/^\d{9}$/) do
      message "must be a 9-digit number"
    end

    validate match(:siret, ~r/^\d{14}$/) do
      where present(:siret)
      message "must be a 14-digit number"
    end

    validate match(:vat_number, ~r/^[A-Z]{2}[0-9A-Z]{2,13}$/) do
      where present(:vat_number)
      message "must be a valid EU VAT number"
    end
  end

  actions do
    defaults [:read, :destroy]

    create :register do
      description "Register a new company on the platform."
      accept [
        :name,
        :siren,
        :siret,
        :vat_number,
        :address_street,
        :address_city,
        :address_postal_code,
        :address_country,
        :role,
        :ppf_routing_id
      ]
    end

    update :update_details do
      description "Update company contact and address information."
      accept [
        :name,
        :address_street,
        :address_city,
        :address_postal_code,
        :address_country,
        :ppf_routing_id
      ]
    end

    update :suspend do
      description "Suspend a company's operations on the platform."
      accept []
      change set_attribute(:status, :suspended)
    end

    update :close do
      description "Mark a company as permanently closed / deregistered."
      accept []
      change set_attribute(:status, :closed)
    end

    update :reactivate do
      description "Reactivate a previously suspended company."
      accept []
      change set_attribute(:status, :active)
    end

    read :active do
      description "List all active companies."
      filter expr(status == :active)
    end

    read :by_siren do
      description "Fetch a company by its SIREN."
      argument :siren, :string, allow_nil?: false
      filter expr(siren == ^arg(:siren))
    end
  end

  calculations do
    calculate :full_address, :string, expr(
      fragment(
        "concat_ws(', ', ?, concat_ws(' ', ?, ?), ?)",
        address_street,
        address_postal_code,
        address_city,
        address_country
      )
    )
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    policy action(:register) do
      authorize_if actor_attribute_equals(:role, :admin)
      authorize_if actor_attribute_equals(:role, :operator)
    end

    policy action(:update_details) do
      authorize_if actor_attribute_equals(:role, :admin)
      authorize_if actor_attribute_equals(:role, :operator)
    end

    policy action(:suspend) do
      authorize_if actor_attribute_equals(:role, :admin)
    end

    policy action(:close) do
      authorize_if actor_attribute_equals(:role, :admin)
    end

    policy action(:reactivate) do
      authorize_if actor_attribute_equals(:role, :admin)
    end

    policy action_type(:destroy) do
      authorize_if actor_attribute_equals(:role, :admin)
    end
  end
end
