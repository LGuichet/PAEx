defmodule PAEx.EReporting.EReportLine do
  @moduledoc """
  A single transaction line within an e-reporting submission.

  For B2C and international B2B reports, each line represents one transaction.
  For payment reports, each line references a previously reported invoice.
  """
  use Ash.Resource,
    otp_app: :pa_ex,
    domain: PAEx.EReporting,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "e_report_lines"
    repo PAEx.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :transaction_date, :date do
      allow_nil? false
      public? true
    end

    # Free-text reference assigned by the seller (e.g., POS receipt number)
    attribute :transaction_ref, :string do
      allow_nil? true
      public? true
      constraints max_length: 100
    end

    attribute :customer_country, :string do
      allow_nil? true
      public? true
      description "ISO 3166-1 alpha-2 country code of the customer (for international reports)."
      constraints min_length: 2, max_length: 2
    end

    attribute :customer_vat_number, :string do
      allow_nil? true
      public? true
      description "VAT number of the customer (for international B2B reports)."
      constraints max_length: 20
    end

    # Monetary amounts (euro cents)
    attribute :amount_excl_tax, :integer do
      allow_nil? false
      public? true
    end

    attribute :vat_rate, :decimal do
      allow_nil? false
      public? true
      description "Applicable VAT rate as a percentage."
      constraints greater_than_or_equal_to: 0, less_than_or_equal_to: 100
    end

    attribute :vat_amount, :integer do
      allow_nil? false
      public? true
    end

    attribute :amount_incl_tax, :integer do
      allow_nil? false
      public? true
    end

    attribute :currency, :string do
      allow_nil? false
      public? true
      default "EUR"
      constraints min_length: 3, max_length: 3
    end

    create_timestamp :inserted_at
  end

  relationships do
    belongs_to :e_report, PAEx.EReporting.EReport do
      allow_nil? false
      public? true
    end
  end

  validations do
    validate compare(:amount_excl_tax, greater_than_or_equal_to: 0)
    validate compare(:vat_amount, greater_than_or_equal_to: 0)
    validate compare(:amount_incl_tax, greater_than_or_equal_to: 0)
  end

  actions do
    defaults [:read, :destroy]

    create :add_line do
      description "Add a transaction line to a draft e-report."
      accept [
        :transaction_date,
        :transaction_ref,
        :customer_country,
        :customer_vat_number,
        :amount_excl_tax,
        :vat_rate,
        :vat_amount,
        :amount_incl_tax,
        :currency,
        :e_report_id
      ]
    end
  end
end
