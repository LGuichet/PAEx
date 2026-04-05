defmodule PAExWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :pa_ex

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: {__MODULE__, :session_options, []}]],
    longpoll: false

  plug Plug.Static,
    at: "/",
    from: :pa_ex,
    gzip: false,
    only: PAExWeb.static_paths()

  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :pa_ex
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, session_options()
  plug PAExWeb.Router

  def session_options do
    [
      store: :cookie,
      key: "_pa_ex_key",
      signing_salt: "pa_ex_signing_salt",
      same_site: "Lax"
    ]
  end
end
