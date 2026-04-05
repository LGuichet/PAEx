defmodule PAExWeb.TransmissionEventController do
  @moduledoc "Read-only controller for TransmissionEvent audit records."
  use PAExWeb, :controller

  alias PAEx.Transmission
  alias PAEx.Transmission.TransmissionEvent

  action_fallback PAExWeb.FallbackController

  def index(conn, _params) do
    events = Ash.read!(TransmissionEvent, domain: Transmission)
    json(conn, %{data: Enum.map(events, &event_json/1)})
  end

  def show(conn, %{"id" => id}) do
    event = Ash.get!(TransmissionEvent, id, domain: Transmission)
    json(conn, %{data: event_json(event)})
  end

  defp event_json(%TransmissionEvent{} = e) do
    %{
      id: e.id,
      direction: e.direction,
      counterparty_type: e.counterparty_type,
      counterparty_id: e.counterparty_id,
      event_type: e.event_type,
      status: e.status,
      reference_id: e.reference_id,
      reference_type: e.reference_type,
      payload_summary: e.payload_summary,
      http_status_code: e.http_status_code,
      error_message: e.error_message,
      retry_count: e.retry_count,
      sent_at: e.sent_at,
      acked_at: e.acked_at,
      inserted_at: e.inserted_at
    }
  end
end
