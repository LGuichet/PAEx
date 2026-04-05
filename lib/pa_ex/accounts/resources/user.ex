defmodule PAEx.Accounts.User do
  @moduledoc """
  Represents a platform user.

  Users authenticate with email + password and hold a role that controls what
  actions they can perform within the platform.
  """
  use Ash.Resource,
    otp_app: :pa_ex,
    domain: PAEx.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "users"
    repo PAEx.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :ci_string do
      allow_nil? false
      public? true
    end

    attribute :hashed_password, :string do
      allow_nil? false
      sensitive? true
    end

    attribute :role, :atom do
      constraints one_of: [:admin, :operator, :api_client]
      default :operator
      allow_nil? false
      public? true
    end

    attribute :confirmed_at, :utc_datetime_usec do
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  identities do
    identity :unique_email, [:email]
  end

  validations do
    validate match(:email, ~r/^[^\s]+@[^\s]+$/) do
      message "must be a valid email address"
    end
  end

  actions do
    defaults [:read, :destroy]

    create :register do
      description "Register a new user with email and password."
      accept [:email, :role]

      argument :password, :string do
        allow_nil? false
        sensitive? true
        constraints min_length: 12
      end

      argument :password_confirmation, :string do
        allow_nil? false
        sensitive? true
      end

      validate confirm(:password, :password_confirmation)

      change fn changeset, _ ->
        password = Ash.Changeset.get_argument(changeset, :password)

        Ash.Changeset.change_attribute(
          changeset,
          :hashed_password,
          Bcrypt.hash_pwd_salt(password)
        )
      end
    end

    update :confirm_email do
      description "Mark the user's email address as confirmed."
      accept []
      change set_attribute(:confirmed_at, &DateTime.utc_now/0)
    end

    update :change_password do
      description "Allow a user to change their password."
      accept []

      argument :current_password, :string do
        allow_nil? false
        sensitive? true
      end

      argument :new_password, :string do
        allow_nil? false
        sensitive? true
        constraints min_length: 12
      end

      argument :new_password_confirmation, :string do
        allow_nil? false
        sensitive? true
      end

      validate confirm(:new_password, :new_password_confirmation)

      change fn changeset, _ ->
        new_password = Ash.Changeset.get_argument(changeset, :new_password)

        Ash.Changeset.change_attribute(
          changeset,
          :hashed_password,
          Bcrypt.hash_pwd_salt(new_password)
        )
      end
    end
  end

  calculations do
    calculate :confirmed?, :boolean, expr(not is_nil(confirmed_at))
  end

  policies do
    policy action_type(:read) do
      authorize_if expr(id == ^actor(:id))
      authorize_if actor_attribute_equals(:role, :admin)
    end

    policy action(:register) do
      authorize_if always()
    end

    policy action(:confirm_email) do
      authorize_if expr(id == ^actor(:id))
    end

    policy action(:change_password) do
      authorize_if expr(id == ^actor(:id))
    end

    policy action_type(:destroy) do
      authorize_if actor_attribute_equals(:role, :admin)
    end
  end
end
