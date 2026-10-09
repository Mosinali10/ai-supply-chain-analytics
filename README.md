# AI-Powered Supply Chain Analytics & Automation

**Live project page:** https://mosinali10.github.io/ai-supply-chain-analytics/

An end-to-end analytics system: raw order data is profiled, cleaned and validated in Python, loaded into PostgreSQL (raw, staging, analytics), turned into reconciled KPIs in SQL, shown in a Power BI dashboard, and reported by an n8n workflow with a checked AI summary step.

## Business problem
Operations managers need to know how many orders ship late, where the delays concentrate, and which shipping modes are exceptions. This project answers that from order data, with every KPI defined, reconciled and traceable.

## Key results (all orders, Jan 2015 - Jan 2018)
| KPI | Value |
|---|---|
| Total orders | 65,752 |
| Eligible orders (not canceled) | 62,897 (2,855 excluded) |
| On-time | 26,849 (42.69%) |
| Late | 36,048 (57.31%) |
| Avg order-to-ship days | 3.50 |
| Total order value | 33,054,402.38 |

Delay rate by shipping mode: First Class 100.00% (9,602 of 9,602), Second Class 79.99%, Same Day 48.37%, Standard Class 39.85%.

**Caution:** the delay pattern by shipping mode is unusually uniform and may reflect how the dataset was built. Treat these as dataset findings, not proven operational causes (see `docs/kpi_definitions.md`).

## Architecture
Raw CSV -> Python profiling, cleaning, validation -> PostgreSQL (`raw` -> `staging` -> `analytics`) -> SQL KPI views -> Power BI dashboard -> n8n workflow -> logged report and checked AI summary.

## Repository
| Folder | Contents |
|---|---|
| `python/` | `01_profile.py`, `02_clean.py`, `sanitize_n8n_export.py` |
| `sql/` | `01_schema.sql` to `09_report_log_ai.sql`, `load_raw.sql` |
| `powerbi/` | `supply_chain_dashboard.pbix` (5 pages) |
| `n8n/` | `KPI Report.json` workflow export, AI checker and its tests |
| `docs/` | KPI definitions, cleaning decisions, n8n workflow, AI layer, AI prompt |

## KPI definitions and limits
Formulas, numerators, denominators and filters: `docs/kpi_definitions.md`. Cleaning rules and evidence: `docs/cleaning_decisions.md`.

**Unavailable because the dataset lacks the fields:** In-Full %, OTIF %, supplier KPIs, and true delivery cycle time (there is no delivery date, so cycle time is order-to-ship days).

## Dashboard
Pages: Supply Chain Performance Overview, Delivery & Operations Analysis, Shipping Mode Performance, Shipping Mode Exception Detail (drill-through), Customer & Product Performance.
Power BI values were compared with SQL on the unfiltered pages: total, eligible, on-time %, delay rate, late orders and average order-to-ship days all match.

## n8n workflow
Reads KPIs, monthly delay rates and exceptions from PostgreSQL, validates them, builds a report from calculated values only, and logs every run (success or failure) in `analytics.report_log`. A broken input is rejected visibly and logged as `failed`. Details and tests: `docs/n8n_workflow.md`.

## AI insight layer (mock mode)
The n8n workflow builds a payload from validated KPIs, exceptions and monthly delay rates. A summary is created from that payload and verified by a code checker (`n8n/ai_check.js`). Numbers not found in the payload and unsupported causal wording are rejected, and a rejected text is never stored.

**The summary step is a fixed template, not an AI model.** No AI call was run and no API key was used. A real model can replace the template, and the same checker would verify its output.

Details, tests and limits: `docs/ai_layer.md`. Prompt: `docs/ai_prompt.md`.

## Setup
1. Install PostgreSQL and create a database named `supply_chain`.
2. Create a Python environment and run `pip install -r requirements.txt`.
3. Copy `.env.example` to `.env` and fill in your own values for connecting to PostgreSQL. The Python scripts do not need it. Never commit `.env`.
4. Place the raw CSV files in `data/raw/` (not committed because of size).
5. Run the scripts in `python/`, then the scripts in `sql/` in order (see `sql/load_raw.sql` for loading).
6. Open `powerbi/supply_chain_dashboard.pbix` and point it at your database.
7. Import `n8n/KPI Report.json` into n8n and create a Postgres credential named `Postgres account` in n8n only.
## Status
| Item | Status |
|---|---|
| Python, PostgreSQL, SQL KPIs, Power BI, n8n | Done |
| AI layer | Done in mock mode; no real model tested |
| Architecture diagram (`docs/architecture.md`), QA checklist (`docs/qa_checklist.md`) | Done |
| Live project page and dashboard PDF | Done |
| Real AI model call, `skipped` path, database-down failure test | Not tested |