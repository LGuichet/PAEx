defmodule PAEx.Invoices.InvoiceLine do
  @moduledoc """
  A single line item on an electronic invoice.

  Each line captures:
    * the product or service reference
    * quantity and unit of measure
    * unit price (excluding VAT)
    * applicable VAT rate
    * computed totals (excl. VAT, VAT amount, incl. VAT)

  All monetary amounts are stored in **euro cents** (integer) to avoid
  floating-point rounding issues.
  """
  use Ash.Resource,
    otp_app: :pa_ex,
    domain: PAEx.Invoices,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "invoice_lines"
    repo PAEx.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :line_number, :integer do
      allow_nil? false
      public? true
      description "Position of this line on the invoice (1-based)."
    end

    attribute :description, :string do
      allow_nil? false
      public? true
      constraints max_length: 500
    end

    attribute :product_ref, :string do
      allow_nil? true
      public? true
      constraints max_length: 100
    end

    attribute :quantity, :decimal do
      allow_nil? false
      public? true
      constraints greater_than: 0
    end

    attribute :unit_of_measure, :string do
      allow_nil? false
      public? true
      default "EA"
      description "UN/ECE Recommendation 20 unit code (e.g. EA = each, KGM = kilogram)."
      constraints max_length: 10
    end

    # Stored as integer (euro cents)
    attribute :unit_price, :integer do
      allow_nil? false
      public? true
      description "Net unit price excluding VAT, in euro cents."
    end

    # VAT rate as a percentage stored as decimal (e.g. 20.0, 10.0, 5.5, 0.0)
    attribute :vat_rate, :decimal do
      allow_nil? false
      public? true
      description "VAT rate as a percentage (e.g. 20.0 for 20%)."
      constraints greater_than_or_equal_to: 0, less_than_or_equal_to: 100
    end

    # Computed totals (euro cents)
    attribute :line_amount_excl_tax, :integer do
      allow_nil? false
      public? true
      description "quantity × unit_price, in euro cents."
    end

    attribute :line_vat_amount, :integer do
      allow_nil? false
      public? true
      description "VAT amount for this line, in euro cents."
    end

    attribute :line_amount_incl_tax, :integer do
      allow_nil? false
      public? true
      description "line_amount_excl_tax + line_vat_amount, in euro cents."
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :invoice, PAEx.Invoices.Invoice do
      allow_nil? false
      public? true
    end
  end

  validations do
    validate compare(:unit_price, greater_than_or_equal_to: 0) do
      message "cannot be negative"
    end

    validate compare(:line_amount_excl_tax, greater_than_or_equal_to: 0) do
      message "cannot be negative"
    end

    validate compare(:line_vat_amount, greater_than_or_equal_to: 0) do
      message "cannot be negative"
    end
  end

  actions do
    defaults [:read, :create, :update, :destroy]
  end
end
