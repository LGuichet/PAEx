# PAEx — Plateforme Agréée Elixir

**PAEx** is an open-source reference implementation of a French accredited partner
dematerialization platform (**Plateforme Agréée** / PDP) for mandatory
e-invoicing (_facturation électronique_) and e-reporting, built with Elixir,
Phoenix, Ecto and the [Ash Framework](https://ash-hq.org/).

---

## Background

France is rolling out mandatory B2B e-invoicing for all VAT-registered companies
(large companies from 2026, SMEs from 2027). Every invoice must transit through
either the public portal (PPF – _Portail Public de Facturation_) or an accredited
private PDP. E-reporting also covers B2C and international B2B transactions not
subject to e-invoicing.

PAEx demonstrates how such a platform can be built on the Elixir/Phoenix/Ash
stack, providing:

- **Structured invoice lifecycle management** aligned with the 11 official DGFiP
  invoice statuses
- **Multi-format support**: Factur-X (PDF/A-3 + XML), UBL, and CII
- **E-reporting** for B2C, cross-border B2B, and payment flows
- **Full transmission audit trail** for every exchange with the PPF and other PDPs
- **Company directory** with SIREN/SIRET identifiers and PPF routing IDs
- **Role-based access control** via Ash Policies (admin / operator / api_client)
- **JSON REST API** for programmatic integration

---

## Technology Stack

| Layer          | Technology                                |
|----------------|-------------------------------------------|
| Language       | Elixir ≥ 1.16                             |
| Web framework  | Phoenix 1.7 + LiveView                    |
| Domain logic   | Ash Framework 3.x                         |
| Database       | PostgreSQL 14+ via AshPostgres / Ecto SQL |
| API            | JSON REST (AshJsonApi)                    |
| Auth           | Ash Policies + Bcrypt                     |

---

## Domain Model

```
PAEx.Accounts          → User, Token
PAEx.Companies         → Company (SIREN / SIRET)
PAEx.Invoices          → Invoice, InvoiceLine, StatusEvent
PAEx.EReporting        → EReport, EReportLine
PAEx.Transmission      → TransmissionEvent
```

### Invoice lifecycle (`PAEx.Invoices.Invoice`)

```
deposee
  ├─[valid]────► en_cours_de_traitement
  │                     └─[routed]──► en_cours_d_emission
  │                                         └─[delivered]──► emise
  │                                                            ├─[refused]──► refusee
  │                                                            └─[accepted]─► acceptee
  │                                                                               └─► mise_en_paiement
  │                                                                                         └─► comptabilisee
  ├─[invalid]──► rejetee
  └─(any stage before comptabilisee) ──► annulee / en_litige
```

### E-reporting (`PAEx.EReporting.EReport`)

Report types: `b2c` · `b2b_international` · `payment`  
Statuses: `draft` → `submitted` → `accepted` / `rejected`

### Transmission audit (`PAEx.Transmission.TransmissionEvent`)

Records every outbound (to PPF/PDP/ERP) and inbound (webhooks, ACKs) message.

---

## Getting Started

### Prerequisites

- Elixir ≥ 1.16 / OTP ≥ 26
- PostgreSQL ≥ 14
- Node.js ≥ 18 (for asset pipeline)

### Setup

```bash
# Install dependencies
mix deps.get

# Create and migrate the database
mix ecto.setup

# Start the server
mix phx.server
```

The application is now available at **http://localhost:4000**.

### Running Tests

```bash
mix test
```

---

## REST API Overview

All API endpoints are prefixed with `/api/v1`.

### Companies

| Method | Path                   | Description               |
|--------|------------------------|---------------------------|
| GET    | `/companies`           | List all companies        |
| POST   | `/companies`           | Register a new company    |
| GET    | `/companies/:id`       | Get a specific company    |
| PUT    | `/companies/:id`       | Update company details    |

### Invoices

| Method | Path                                | Description                   |
|--------|-------------------------------------|-------------------------------|
| GET    | `/invoices`                         | List invoices                 |
| POST   | `/invoices`                         | Submit a new invoice          |
| GET    | `/invoices/:id`                     | Get invoice details           |
| POST   | `/invoices/:id/start_processing`    | Start processing              |
| POST   | `/invoices/:id/reject`              | Reject invoice                |
| POST   | `/invoices/:id/start_emission`      | Start routing to recipient    |
| POST   | `/invoices/:id/mark_emitted`        | Confirm delivery              |
| POST   | `/invoices/:id/refuse`              | Recipient refuses invoice     |
| POST   | `/invoices/:id/accept`              | Recipient accepts invoice     |
| POST   | `/invoices/:id/initiate_payment`    | Initiate payment              |
| POST   | `/invoices/:id/mark_accounted`      | Mark invoice as accounted     |
| POST   | `/invoices/:id/raise_dispute`       | Raise a dispute               |
| POST   | `/invoices/:id/cancel`              | Cancel the invoice            |

### E-Reporting

| Method | Path                         | Description                    |
|--------|------------------------------|--------------------------------|
| GET    | `/e_reports`                 | List e-reports                 |
| POST   | `/e_reports`                 | Create a draft e-report        |
| GET    | `/e_reports/:id`             | Get report details             |
| POST   | `/e_reports/:id/submit`      | Submit report to PPF           |
| POST   | `/e_reports/:id/acknowledge` | Record PPF acceptance          |
| POST   | `/e_reports/:id/reject`      | Record PPF rejection           |

### Transmission Events

| Method | Path                          | Description                   |
|--------|-------------------------------|-------------------------------|
| GET    | `/transmission_events`        | List all transmission events  |
| GET    | `/transmission_events/:id`    | Get a specific event          |

---

## Project Structure

```
lib/
├── pa_ex/
│   ├── application.ex
│   ├── repo.ex
│   ├── accounts/
│   │   ├── accounts.ex          # Ash domain
│   │   └── resources/
│   │       ├── user.ex
│   │       └── token.ex
│   ├── companies/
│   │   ├── companies.ex
│   │   └── resources/
│   │       └── company.ex
│   ├── invoices/
│   │   ├── invoices.ex
│   │   └── resources/
│   │       ├── invoice.ex
│   │       ├── invoice_line.ex
│   │       └── status_event.ex
│   ├── e_reporting/
│   │   ├── e_reporting.ex
│   │   └── resources/
│   │       ├── e_report.ex
│   │       └── e_report_line.ex
│   └── transmission/
│       ├── transmission.ex
│       └── resources/
│           └── transmission_event.ex
└── pa_ex_web/
    ├── endpoint.ex
    ├── router.ex
    ├── telemetry.ex
    └── controllers/
        ├── company_controller.ex
        ├── invoice_controller.ex
        ├── e_report_controller.ex
        ├── transmission_event_controller.ex
        └── fallback_controller.ex
```

---

## License

MIT — see [LICENSE](LICENSE).
