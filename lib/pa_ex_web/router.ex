defmodule PAExWeb.Router do
  use PAExWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PAExWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # ── JSON:API routes (Ash) ────────────────────────────────────────────────────

  scope "/api/v1", PAExWeb do
    pipe_through :api

    # Companies
    get "/companies", CompanyController, :index
    post "/companies", CompanyController, :create
    get "/companies/:id", CompanyController, :show
    put "/companies/:id", CompanyController, :update

    # Invoices
    get "/invoices", InvoiceController, :index
    post "/invoices", InvoiceController, :create
    get "/invoices/:id", InvoiceController, :show

    # Invoice lifecycle actions
    post "/invoices/:id/start_processing", InvoiceController, :start_processing
    post "/invoices/:id/reject", InvoiceController, :reject
    post "/invoices/:id/start_emission", InvoiceController, :start_emission
    post "/invoices/:id/mark_emitted", InvoiceController, :mark_emitted
    post "/invoices/:id/refuse", InvoiceController, :refuse
    post "/invoices/:id/accept", InvoiceController, :accept
    post "/invoices/:id/initiate_payment", InvoiceController, :initiate_payment
    post "/invoices/:id/mark_accounted", InvoiceController, :mark_accounted
    post "/invoices/:id/raise_dispute", InvoiceController, :raise_dispute
    post "/invoices/:id/cancel", InvoiceController, :cancel

    # E-reporting
    get "/e_reports", EReportController, :index
    post "/e_reports", EReportController, :create
    get "/e_reports/:id", EReportController, :show
    post "/e_reports/:id/submit", EReportController, :submit
    post "/e_reports/:id/acknowledge", EReportController, :acknowledge
    post "/e_reports/:id/reject", EReportController, :reject

    # Transmission events (read-only via API)
    get "/transmission_events", TransmissionEventController, :index
    get "/transmission_events/:id", TransmissionEventController, :show
  end

  # ── Browser / LiveView routes ─────────────────────────────────────────────────

  scope "/", PAExWeb do
    pipe_through :browser

    live "/", DashboardLive, :index
    live "/invoices", InvoiceLive.Index, :index
    live "/invoices/:id", InvoiceLive.Show, :show
    live "/e_reports", EReportLive.Index, :index
    live "/companies", CompanyLive.Index, :index
  end
end
