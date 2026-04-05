defmodule PAEx.Invoices.InvoiceTest do
  @moduledoc "Unit tests for the Invoice resource and lifecycle transitions."
  use PAEx.DataCase, async: true

  alias PAEx.Companies
  alias PAEx.Companies.Company
  alias PAEx.Invoices
  alias PAEx.Invoices.Invoice

  setup do
    {:ok, emitter} =
      Ash.create(
        Company,
        %{name: "Emitter SA", siren: "111111111", siret: "11111111100011", role: :emitter},
        action: :register,
        domain: Companies
      )

    {:ok, receiver} =
      Ash.create(
        Company,
        %{name: "Receiver SA", siren: "222222222", siret: "22222222200022", role: :receiver},
        action: :register,
        domain: Companies
      )

    {:ok, emitter: emitter, receiver: receiver}
  end

  defp valid_invoice_attrs(emitter_id, receiver_id) do
    %{
      number: "FA-2024-001",
      invoice_type: :facture,
      format: :factur_x,
      issue_date: ~D[2024-01-15],
      due_date: ~D[2024-02-15],
      amount_excl_tax: 10_000,
      amount_vat: 2_000,
      amount_incl_tax: 12_000,
      currency: "EUR",
      emitter_id: emitter_id,
      receiver_id: receiver_id
    }
  end

  describe "submit/1" do
    test "creates an invoice in 'deposee' status", ctx do
      attrs = valid_invoice_attrs(ctx.emitter.id, ctx.receiver.id)

      assert {:ok, invoice} = Ash.create(Invoice, attrs, action: :submit, domain: Invoices)

      assert invoice.status == :deposee
      assert invoice.number == "FA-2024-001"
      assert invoice.amount_excl_tax == 10_000
    end

    test "rejects negative amounts", ctx do
      attrs =
        valid_invoice_attrs(ctx.emitter.id, ctx.receiver.id)
        |> Map.put(:amount_excl_tax, -100)

      assert {:error, %Ash.Error.Invalid{}} =
               Ash.create(Invoice, attrs, action: :submit, domain: Invoices)
    end

    test "rejects due_date before issue_date", ctx do
      attrs =
        valid_invoice_attrs(ctx.emitter.id, ctx.receiver.id)
        |> Map.put(:due_date, ~D[2023-12-01])

      assert {:error, %Ash.Error.Invalid{}} =
               Ash.create(Invoice, attrs, action: :submit, domain: Invoices)
    end
  end

  describe "lifecycle transitions" do
    setup ctx do
      attrs = valid_invoice_attrs(ctx.emitter.id, ctx.receiver.id)
      {:ok, invoice} = Ash.create(Invoice, attrs, action: :submit, domain: Invoices)
      {:ok, invoice: invoice}
    end

    test "deposee → en_cours_de_traitement", ctx do
      assert {:ok, inv} =
               Ash.update(ctx.invoice, %{}, action: :start_processing, domain: Invoices)

      assert inv.status == :en_cours_de_traitement
    end

    test "deposee → rejetee", ctx do
      assert {:ok, inv} =
               Ash.update(ctx.invoice, %{rejection_reason: "Format invalide"},
                 action: :reject,
                 domain: Invoices
               )

      assert inv.status == :rejetee
      assert inv.rejection_reason == "Format invalide"
    end

    test "deposee cannot transition directly to emise", ctx do
      assert {:error, %Ash.Error.Invalid{}} =
               Ash.update(ctx.invoice, %{}, action: :mark_emitted, domain: Invoices)
    end

    test "full happy-path lifecycle", ctx do
      {:ok, inv} = Ash.update(ctx.invoice, %{}, action: :start_processing, domain: Invoices)
      assert inv.status == :en_cours_de_traitement

      {:ok, inv} = Ash.update(inv, %{}, action: :start_emission, domain: Invoices)
      assert inv.status == :en_cours_d_emission

      {:ok, inv} =
        Ash.update(inv, %{ppf_submission_id: "PPF-123"}, action: :mark_emitted, domain: Invoices)

      assert inv.status == :emise
      assert inv.ppf_submission_id == "PPF-123"

      {:ok, inv} = Ash.update(inv, %{}, action: :accept, domain: Invoices)
      assert inv.status == :acceptee

      {:ok, inv} = Ash.update(inv, %{}, action: :initiate_payment, domain: Invoices)
      assert inv.status == :mise_en_paiement

      {:ok, inv} = Ash.update(inv, %{}, action: :mark_accounted, domain: Invoices)
      assert inv.status == :comptabilisee
    end

    test "can cancel an invoice in deposee status", ctx do
      assert {:ok, inv} = Ash.update(ctx.invoice, %{}, action: :cancel, domain: Invoices)
      assert inv.status == :annulee
    end

    test "cannot cancel a comptabilisee invoice", ctx do
      {:ok, inv} = Ash.update(ctx.invoice, %{}, action: :start_processing, domain: Invoices)
      {:ok, inv} = Ash.update(inv, %{}, action: :start_emission, domain: Invoices)
      {:ok, inv} = Ash.update(inv, %{}, action: :mark_emitted, domain: Invoices)
      {:ok, inv} = Ash.update(inv, %{}, action: :accept, domain: Invoices)
      {:ok, inv} = Ash.update(inv, %{}, action: :initiate_payment, domain: Invoices)
      {:ok, inv} = Ash.update(inv, %{}, action: :mark_accounted, domain: Invoices)

      assert {:error, %Ash.Error.Invalid{}} =
               Ash.update(inv, %{}, action: :cancel, domain: Invoices)
    end

    test "can raise dispute on emise invoice", ctx do
      {:ok, inv} = Ash.update(ctx.invoice, %{}, action: :start_processing, domain: Invoices)
      {:ok, inv} = Ash.update(inv, %{}, action: :start_emission, domain: Invoices)
      {:ok, inv} = Ash.update(inv, %{}, action: :mark_emitted, domain: Invoices)

      assert {:ok, inv} = Ash.update(inv, %{}, action: :raise_dispute, domain: Invoices)
      assert inv.status == :en_litige
    end
  end
end
