defmodule PAEx.EReporting.EReport do
  @moduledoc """
  A periodic e-reporting submission sent to the PPF by a company.

  ## Report types
    * `:b2c`               – aggregated B2C (consumer) sales data
    * `:b2b_international` – B2B cross-border invoice data
    * `:payment`           – payment information for previously reported invoices

  ## Statuses
    * `:draft`      – being compiled, not yet sent
    * `:submitted`  – transmitted to the PPF, awaiting acknowledgement
    * `:accepted`   – acknowledged and accepted by the PPF
    * `:rejected`   – rejected by the PPF (must be corrected and resubmitted)

  ## Reporting frequency
  The DGFiP allows weekly or monthly reporting depending on the company's VAT
  filing regime. The `period_start` / `period_end` attributes capture the
  exact period covered.
  """
  use Ash.Resource,
    otp_app: :pa_ex,
    domain: PAEx.EReporting,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  @report_types [:b2c, :b2b_international, :payment]
  @statuses [:draft, :submitted, :accepted, :rejected]

  postgres do
    table "e_reports"
    repo PAEx.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :report_type, :atom do
      constraints one_of: @report_types
      allow_nil? false
      public? true
    end

    attribute :status, :atom do
      constraints one_of: @statuses
      default :draft
      allow_nil? false
      public? true
    end

    # The calendar period this report covers
    attribute :period_start, :date do
      allow_nil? false
      public? true
    end

    attribute :period_end, :date do
      allow_nil? false
      public? true
    end

    # Aggregated monetary totals (in euro cents)
    attribute :total_amount_excl_tax, :integer do
      allow_nil? false
      default 0
      public? true
      description "Total amount excluding taxes for the period, in euro cents."
    end

    attribute :total_vat_amount, :integer do
      allow_nil? false
      default 0
      public? true
      description "Total VAT amount for the period, in euro cents."
    end

    attribute :total_amount_incl_tax, :integer do
      allow_nil? false
      default 0
      public? true
      description "Total amount including taxes for the period, in euro cents."
    end

    attribute :transaction_count, :integer do
      allow_nil? false
      default 0
      public? true
    end

    # PPF submission tracking
    attribute :ppf_submission_id, :string do
      allow_nil? true
      public? true
    end

    attribute :submitted_at, :utc_datetime_usec do
      allow_nil? true
      public? true
    end

    attribute :ppf_acknowledgement_id, :string do
      allow_nil? true
      public? true
    end

    attribute :rejection_reason, :string do
      allow_nil? true
      public? true
      constraints max_length: 2000
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :company, PAEx.Companies.Company do
      allow_nil? false
      public? true
    end

    has_many :lines, PAEx.EReporting.EReportLine do
      destination_attribute :e_report_id
    end
  end

  validations do
    validate compare(:period_end, greater_than_or_equal_to: :period_start) do
      message "period_end must be on or after period_start"
    end

    validate compare(:total_amount_excl_tax, greater_than_or_equal_to: 0)
    validate compare(:total_vat_amount, greater_than_or_equal_to: 0)
    validate compare(:total_amount_incl_tax, greater_than_or_equal_to: 0)
    validate compare(:transaction_count, greater_than_or_equal_to: 0)
  end

  actions do
    defaults [:read, :destroy]

    create :create_draft do
      description "Create a new draft e-report for a given period."
      accept [:report_type, :period_start, :period_end, :company_id]
    end

    update :update_totals do
      description "Update aggregated totals after lines have been added."
      accept [
        :total_amount_excl_tax,
        :total_vat_amount,
        :total_amount_incl_tax,
        :transaction_count
      ]

      validate attribute_equals(:status, :draft) do
        message "Only draft reports can have their totals updated"
      end
    end

    update :submit do
      description "Transmit the e-report to the PPF."
      accept [:ppf_submission_id]

      validate attribute_equals(:status, :draft) do
        message "Only draft reports can be submitted"
      end

      change set_attribute(:status, :submitted)
      change set_attribute(:submitted_at, &DateTime.utc_now/0)
    end

    update :acknowledge_acceptance do
      description "Record PPF acceptance acknowledgement."
      accept [:ppf_acknowledgement_id]

      validate attribute_equals(:status, :submitted) do
        message "Only submitted reports can be acknowledged"
      end

      change set_attribute(:status, :accepted)
    end

    update :reject do
      description "Record PPF rejection with reason."
      accept [:rejection_reason]

      validate attribute_equals(:status, :submitted) do
        message "Only submitted reports can be rejected"
      end

      change set_attribute(:status, :rejected)
    end

    update :reopen do
      description "Reopen a rejected report for correction."
      accept []

      validate attribute_equals(:status, :rejected) do
        message "Only rejected reports can be reopened"
      end

      change set_attribute(:status, :draft)
      change set_attribute(:rejection_reason, nil)
      change set_attribute(:ppf_submission_id, nil)
      change set_attribute(:submitted_at, nil)
    end

    read :by_company_and_period do
      description "Fetch reports for a specific company and period."
      argument :company_id, :uuid, allow_nil?: false
      argument :period_start, :date, allow_nil?: false
      argument :period_end, :date, allow_nil?: false

      filter expr(
               company_id == ^arg(:company_id) and
                 period_start >= ^arg(:period_start) and
                 period_end <= ^arg(:period_end)
             )
    end
  end

  calculations do
    calculate :total_excl_tax_eur, :decimal, expr(total_amount_excl_tax / 100.0)
    calculate :total_vat_eur, :decimal, expr(total_vat_amount / 100.0)
    calculate :total_incl_tax_eur, :decimal, expr(total_amount_incl_tax / 100.0)
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    policy action(:create_draft) do
      authorize_if actor_attribute_equals(:role, :admin)
      authorize_if actor_attribute_equals(:role, :operator)
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
