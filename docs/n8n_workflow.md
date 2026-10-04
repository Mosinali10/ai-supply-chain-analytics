# n8n Workflow: KPI Report

Export: `n8n/KPI Report.json`. n8n 2.35.7, run locally.

## Purpose
Read the KPI results and the exception list from PostgreSQL, validate them, and build a report that uses only values calculated in SQL.

## Flow
Manual Trigger -> Get KPIs -> Get Exceptions -> Build Report

| Node | Type | What it does |
|---|---|---|
| When clicking 'Execute workflow' | Manual trigger | Starts a run (scheduling is not set up yet) |
| Get KPIs | PostgreSQL, Execute Query | `SELECT * FROM analytics.kpi_summary;` |
| Get Exceptions | PostgreSQL, Execute Query | `SELECT * FROM analytics.exceptions_shipping_mode ORDER BY delay_rate_pct DESC;` |
| Build Report | Code (JavaScript) | Validates both inputs, then writes the report text |

## Exception rule (sql/06_exceptions.sql)
A shipping mode is an exception when its delay rate is above the overall delay rate and it has at least 500 eligible orders. These thresholds are a documented decision and can be changed.

## Validation in Build Report
The run stops with an error if any of these fail:
- A KPI field is missing or not numeric (Postgres sends numbers as text, so the code converts them first).
- eligible orders + excluded canceled orders does not equal total orders.
- on-time orders + late orders does not equal eligible orders.
- eligible orders is not above zero.
- the delay rate does not match late orders / eligible orders (tolerance 0.01).
- an exception row is missing a required field.

## Acceptance tests
| Test | Result |
|---|---|
| Normal run succeeds | Passed. All four nodes ran; Build Report returned `validation: passed`. |
| KPI values match SQL | Passed. 65,752 orders, 62,897 eligible, 2,855 excluded, 26,849 on time (42.69%), 36,048 late (57.31%), 3.50 average order-to-ship days. |
| Output has KPI summary and exceptions | Passed. First Class: 9,602 late of 9,602 eligible (100.00%). Second Class: 9,803 late of 12,256 eligible (79.99%). |
| Broken input is rejected visibly | Passed. The KPI query was temporarily changed to return eligible orders + 100. Build Report failed with: "eligible + excluded does not equal total orders; on-time + late does not equal eligible orders; delay rate does not match late / eligible". No report was produced. The real query was restored afterwards. |
| AI uses only supplied metrics | Not applicable yet (Phase 9). |
| Failure path documented | This section. |

## Failure path
- **Validation fails:** Build Report throws an error and turns red. n8n marks the run as failed and lists the problems. No report is produced. Fix the data or the SQL view, then run again.
- **Database unreachable or a query fails:** the Get KPIs or Get Exceptions node errors and the run stops before Build Report. **Not tested.**
- **Error alert (email or Slack):** not set up.
- **Run logging:** n8n's Executions tab shows past runs. A separate success or failure log is not set up yet.

## Setup
1. Run the SQL scripts in `sql/` in order (01 to 06).
2. In n8n, create a Postgres credential named `Postgres account`: host `localhost`, database `supply_chain`, user `postgres`, port 5432, SSL disabled. Enter the password in n8n only. The export does not contain it.
3. Import `n8n/KPI Report.json` into n8n and run it.
4. Run n8n in its own Command Prompt window and leave it open.

## Known limits
- Manual trigger only, no schedule.
- The report is shown in n8n but not yet saved or sent anywhere.
- Report times are in UTC.