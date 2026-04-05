defmodule PAEx.Transmission.TransmissionEventTest do
  @moduledoc "Unit tests for TransmissionEvent."
  use PAEx.DataCase, async: true

  alias PAEx.Transmission
  alias PAEx.Transmission.TransmissionEvent

  @invoice_id "00000000-0000-0000-0000-000000000001"

  describe "record_outbound/1" do
    test "creates a pending outbound event" do
      assert {:ok, event} =
               Ash.create(
                 TransmissionEvent,
                 %{
                   counterparty_type: :ppf,
                   event_type: :invoice_submission,
                   reference_id: @invoice_id,
                   reference_type: "PAEx.Invoices.Invoice",
                   payload_summary: "Invoice FA-2024-001"
                 },
                 action: :record_outbound,
                 domain: Transmission
               )

      assert event.direction == :outbound
      assert event.status == :pending
      assert event.retry_count == 0
    end
  end

  describe "outbound lifecycle" do
    setup do
      {:ok, event} =
        Ash.create(
          TransmissionEvent,
          %{
            counterparty_type: :ppf,
            event_type: :invoice_submission,
            reference_id: @invoice_id,
            reference_type: "PAEx.Invoices.Invoice"
          },
          action: :record_outbound,
          domain: Transmission
        )

      {:ok, event: event}
    end

    test "mark_sent transitions pending → sent", ctx do
      assert {:ok, sent} =
               Ash.update(ctx.event, %{http_status_code: 202},
                 action: :mark_sent,
                 domain: Transmission
               )

      assert sent.status == :sent
      assert not is_nil(sent.sent_at)
    end

    test "acknowledge transitions sent → acked", ctx do
      {:ok, sent} =
        Ash.update(ctx.event, %{http_status_code: 202},
          action: :mark_sent,
          domain: Transmission
        )

      assert {:ok, acked} =
               Ash.update(sent, %{http_status_code: 200},
                 action: :acknowledge,
                 domain: Transmission
               )

      assert acked.status == :acked
      assert not is_nil(acked.acked_at)
    end

    test "mark_failed increments retry_count", ctx do
      assert {:ok, failed} =
               Ash.update(ctx.event, %{error_message: "Connection refused"},
                 action: :mark_failed,
                 domain: Transmission
               )

      assert failed.status == :failed
      assert failed.retry_count == 1
    end

    test "retry resets failed event to pending", ctx do
      {:ok, failed} =
        Ash.update(ctx.event, %{error_message: "Timeout"},
          action: :mark_failed,
          domain: Transmission
        )

      assert {:ok, retried} = Ash.update(failed, %{}, action: :retry, domain: Transmission)
      assert retried.status == :pending
      assert retried.retry_count == 1
    end
  end

  describe "record_inbound/1" do
    test "creates a received inbound event" do
      assert {:ok, event} =
               Ash.create(
                 TransmissionEvent,
                 %{
                   counterparty_type: :ppf,
                   event_type: :ppf_webhook,
                   reference_id: @invoice_id,
                   reference_type: "PAEx.Invoices.Invoice",
                   http_status_code: 200
                 },
                 action: :record_inbound,
                 domain: Transmission
               )

      assert event.direction == :inbound
      assert event.status == :received
    end
  end
end
