defmodule PAEx.Transmission do
  @moduledoc """
  The Transmission domain tracks every message exchange between PAEx and
  external parties: the PPF (Portail Public de Facturation), other PDPs
  (Plateformes de Dématérialisation Partenaires), and customer ERPs.

  Each `TransmissionEvent` is an immutable record of a single message sent or
  received, providing a full audit trail for compliance purposes.
  """
  use Ash.Domain, otp_app: :pa_ex

  resources do
    resource PAEx.Transmission.TransmissionEvent
  end
end
