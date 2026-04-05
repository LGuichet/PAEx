defmodule PAEx.Invoices.StatusEvent do
  @moduledoc """
  An immutable audit-trail entry recording every status change in an invoice's
  lifecycle.

  Each event captures:
    * the previous and new status
    * when the transition occurred
    * who or what triggered it (actor, PPF callback, etc.)
    * an optional human-readable note
  """
  use Ash.Resource,
    otp_app: :pa_ex,
    domain: PAEx.Invoices,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "invoice_status_events"
    repo PAEx.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :from_status, :atom do
      allow_nil? true
      public? true
    end

    attribute :to_status, :atom do
      allow_nil? false
      public? true
    end

    attribute :triggered_by, :string do
      allow_nil? true
      public? true
      description "Actor or system that triggered this transition (user id, 'ppf_callback', etc.)."
    end

    attribute :note, :string do
      allow_nil? true
      public? true
      constraints max_length: 1000
    end

    create_timestamp :occurred_at
  end

  relationships do
    belongs_to :invoice, PAEx.Invoices.Invoice do
      allow_nil? false
      public? true
    end
  end

  actions do
    defaults [:read]

    create :record do
      description "Record a new status transition event."
      accept [:from_status, :to_status, :triggered_by, :note, :invoice_id]
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    policy action(:record) do
      authorize_if actor_attribute_equals(:role, :admin)
      authorize_if actor_attribute_equals(:role, :operator)
      authorize_if actor_attribute_equals(:role, :api_client)
    end
  end
end
