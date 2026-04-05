defmodule PAEx.Accounts.Token do
  @moduledoc """
  Short-lived authentication / confirmation tokens linked to a user.

  Token types:
    * `:session`      – API bearer token issued after login
    * `:confirmation` – used to confirm a user's email address
    * `:reset`        – used to reset a forgotten password
  """
  use Ash.Resource,
    otp_app: :pa_ex,
    domain: PAEx.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "tokens"
    repo PAEx.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :token, :string do
      allow_nil? false
      sensitive? true
      public? true
    end

    attribute :context, :atom do
      constraints one_of: [:session, :confirmation, :reset]
      allow_nil? false
      public? true
    end

    attribute :sent_to, :string do
      public? true
    end

    attribute :expires_at, :utc_datetime_usec do
      allow_nil? false
      public? true
    end

    create_timestamp :inserted_at
  end

  relationships do
    belongs_to :user, PAEx.Accounts.User do
      allow_nil? false
      public? true
    end
  end

  validations do
    validate compare(:expires_at, greater_than: &DateTime.utc_now/0) do
      on [:create]
      message "must be in the future"
    end
  end

  actions do
    defaults [:read, :destroy]

    create :generate do
      description "Generate a new token for the given user and context."
      accept [:context, :sent_to, :expires_at, :user_id]

      change fn changeset, _ ->
        raw = :crypto.strong_rand_bytes(32)
        token = Base.url_encode64(raw, padding: false)
        Ash.Changeset.change_attribute(changeset, :token, token)
      end
    end

    read :by_token do
      description "Look up a valid (non-expired) token by its value."
      argument :token, :string, allow_nil?: false
      argument :context, :atom, allow_nil?: false

      filter expr(token == ^arg(:token) and context == ^arg(:context) and expires_at > now())
    end
  end
end
