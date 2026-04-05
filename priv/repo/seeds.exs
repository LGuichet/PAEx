# Seeds — populate the development database with sample data
# Run with: mix run priv/repo/seeds.exs

alias PAEx.Accounts
alias PAEx.Accounts.User
alias PAEx.Companies
alias PAEx.Companies.Company

IO.puts("Seeding database…")

# Create admin user
{:ok, admin} =
  Ash.create(
    User,
    %{
      email: "admin@pa-ex.fr",
      password: "AdminSecret123!",
      password_confirmation: "AdminSecret123!",
      role: :admin
    },
    action: :register,
    domain: Accounts
  )

IO.puts("  ✓ Admin user: #{admin.email}")

# Create a sample emitter company
{:ok, emitter} =
  Ash.create(
    Company,
    %{
      name: "Fournitures Dupont SAS",
      siren: "123456789",
      siret: "12345678900012",
      vat_number: "FR12123456789",
      address_street: "10 Rue de la Paix",
      address_city: "Paris",
      address_postal_code: "75001",
      address_country: "FR",
      role: :emitter,
      ppf_routing_id: "12345678900012"
    },
    action: :register,
    domain: Companies
  )

IO.puts("  ✓ Emitter company: #{emitter.name} (SIREN: #{emitter.siren})")

# Create a sample receiver company
{:ok, receiver} =
  Ash.create(
    Company,
    %{
      name: "Acheteur Martin SARL",
      siren: "987654321",
      siret: "98765432100019",
      vat_number: "FR98987654321",
      address_street: "5 Avenue de Lyon",
      address_city: "Lyon",
      address_postal_code: "69001",
      address_country: "FR",
      role: :receiver,
      ppf_routing_id: "98765432100019"
    },
    action: :register,
    domain: Companies
  )

IO.puts("  ✓ Receiver company: #{receiver.name} (SIREN: #{receiver.siren})")

IO.puts("Done.")
