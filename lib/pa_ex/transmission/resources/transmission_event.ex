defmodule PAEx.Transmission.TransmissionEvent do
  @moduledoc """
  An immutable record of a single message exchanged with an external system.

  ## Directions
    * `:outbound` – PAEx sending a message to an external party
    * `:inbound`  – PAEx receiving a message from an external party

  ## Counterparty types
    * `:ppf`    – the French Public Invoicing Portal (PPF / Chorus Pro)
    * `:pdp`    – another accredited Partner Dematerialization Platform
    * `:erp`    – a customer / supplier ERP system

  ## Event types
    * `:invoice_submission`       – submitting an invoice to the PPF or PDP
    * `:invoice_status_update`    – sending or receiving a lifecycle status update
    * `:e_report_submission`      – submitting a periodic e-reporting payload
    * `:e_report_acknowledgement` – receiving an acknowledgement from the PPF
    * `:directory_lookup`         – querying the PPF directory for a company's PDP
    * `:ppf_webhook`              – inbound webhook notification from the PPF

  ## Statuses
    * `:pending`  – queued but not yet sent
    * `:sent`     – sent, awaiting acknowledgement
    * `:acked`    – acknowledged (success)
    * `:failed`   – send error (will be retried)
    * `:received` – successfully received and parsed (inbound messages)
  """
  use Ash.Resource,
    otp_app: :pa_ex,
    domain: PAEx.Transmission,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  @directions [:outbound, :inbound]
  @counterparty_types [:ppf, :pdp, :erp]
  @event_types [
    :invoice_submission,
    :invoice_status_update,
    :e_report_submission,
    :e_report_acknowledgement,
    :directory_lookup,
    :ppf_webhook
  ]
  @statuses [:pending, :sent, :acked, :failed, :received]

  postgres do
    table "transmission_events"
    repo PAEx.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :direction, :atom do
      constraints one_of: @directions
      allow_nil? false
      public? true
    end

    attribute :counterparty_type, :atom do
      constraints one_of: @counterparty_types
      allow_nil? false
      public? true
    end

    attribute :counterparty_id, :string do
      allow_nil? true
      public? true
      description "SIREN, PDP identifier, or URL of the remote party."
      constraints max_length: 200
    end

    attribute :event_type, :atom do
      constraints one_of: @event_types
      allow_nil? false
      public? true
    end

    attribute :status, :atom do
      constraints one_of: @statuses
      default :pending
      allow_nil? false
      public? true
    end

    # Reference to the business object being transmitted
    attribute :reference_id, :uuid do
      allow_nil? true
      public? true
      description "UUID of the Invoice, EReport, or other entity being transmitted."
    end

    attribute :reference_type, :string do
      allow_nil? true
      public? true
      description "Module name of the referenced entity (e.g. 'PAEx.Invoices.Invoice')."
      constraints max_length: 100
    end

    attribute :payload_summary, :string do
      allow_nil? true
      public? true
      description "Non-sensitive summary of the transmitted payload for debugging."
      constraints max_length: 500
    end

    attribute :http_status_code, :integer do
      allow_nil? true
      public? true
    end

    attribute :error_message, :string do
      allow_nil? true
      public? true
      constraints max_length: 2000
    end

    attribute :retry_count, :integer do
      allow_nil? false
      default 0
      public? true
    end

    attribute :sent_at, :utc_datetime_usec do
      allow_nil? true
      public? true
    end

    attribute :acked_at, :utc_datetime_usec do
      allow_nil? true
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  validations do
    validate compare(:retry_count, greater_than_or_equal_to: 0)
  end

  actions do
    defaults [:read]

    create :record_outbound do
      description "Create a pending outbound transmission event."
      accept [
        :counterparty_type,
        :counterparty_id,
        :event_type,
        :reference_id,
        :reference_type,
        :payload_summary
      ]

      change set_attribute(:direction, :outbound)
    end

    create :record_inbound do
      description "Record an inbound transmission event as received."
      accept [
        :counterparty_type,
        :counterparty_id,
        :event_type,
        :reference_id,
        :reference_type,
        :payload_summary,
        :http_status_code
      ]

      change set_attribute(:direction, :inbound)
      change set_attribute(:status, :received)
    end

    update :mark_sent do
      description "Mark a pending outbound event as sent."
      accept [:http_status_code]

      validate attribute_equals(:status, :pending) do
        message "Only pending events can be marked as sent"
      end

      change set_attribute(:status, :sent)
      change set_attribute(:sent_at, &DateTime.utc_now/0)
    end

    update :acknowledge do
      description "Record a successful acknowledgement from the remote party."
      accept [:http_status_code, :payload_summary]

      validate attribute_equals(:status, :sent) do
        message "Only sent events can be acknowledged"
      end

      change set_attribute(:status, :acked)
      change set_attribute(:acked_at, &DateTime.utc_now/0)
    end

    update :mark_failed do
      description "Record a transmission failure; increments retry_count."
      accept [:error_message, :http_status_code]

      validate attribute_in(:status, [:pending, :sent]) do
        message "Only pending or sent events can be marked as failed"
      end

      change set_attribute(:status, :failed)
      change increment(:retry_count)
    end

    update :retry do
      description "Reset a failed event back to pending for retry."
      accept []

      validate attribute_equals(:status, :failed) do
        message "Only failed events can be retried"
      end

      change set_attribute(:status, :pending)
    end

    read :pending_outbound do
      description "List all outbound events that have not yet been sent."
      filter expr(direction == :outbound and status == :pending)
    end

    read :failed_events do
      description "List all events that have failed (for operational monitoring)."
      filter expr(status == :failed)
    end

    read :for_reference do
      description "List all transmission events for a given business object."
      argument :reference_id, :uuid, allow_nil?: false
      filter expr(reference_id == ^arg(:reference_id))
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if actor_attribute_equals(:role, :admin)
      authorize_if actor_attribute_equals(:role, :operator)
    end

    policy action(:record_outbound) do
      authorize_if actor_attribute_equals(:role, :admin)
      authorize_if actor_attribute_equals(:role, :operator)
      authorize_if actor_attribute_equals(:role, :api_client)
    end

    policy action(:record_inbound) do
      authorize_if actor_attribute_equals(:role, :admin)
      authorize_if actor_attribute_equals(:role, :api_client)
    end

    policy action_type(:update) do
      authorize_if actor_attribute_equals(:role, :admin)
      authorize_if actor_attribute_equals(:role, :operator)
    end
  end
end
