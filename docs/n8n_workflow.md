# n8n Workflow: KPI Report

Export: `n8n/KPI Report.json` (n8n 2.35.7, run locally). Personal fields were removed from the export with `python/sanitize_n8n_export.py`.

## Purpose
Read the KPI results and the exception list from PostgreSQL, validate them, build a report that uses only values calculated in SQL, and log every run. A mock AI step then builds a summary from the same values, a code checker verifies it, and the result is stored with the run. The AI step is a template, not a real model (see `docs/ai_layer.md`).

## Flow
Manual Trigger -> Get KPIs -> Get Monthly and Get Exceptions -> Build Report, then:
- Build Report success output -> Log Run -> Build AI Input -> Mock AI -> Check AI Output -> Log AI Result
- Build Report error output -> Prepare Failure Log -> Log Failure

| Node | Type | What it does |
|---|---|---|
| When clicking 'Execute workflow' | Manual trigger | Starts a run (no schedule yet) |
| Get KPIs | PostgreSQL, Execute Query | `SELECT * FROM analytics.kpi_summary;` |
| Get Monthly | PostgreSQL, Execute Query | Reads `analytics.monthly_delay` |
| Get Exceptions | PostgreSQL, Execute Query | `SELECT * FROM analytics.exceptions_shipping_mode ORDER BY delay_rate_pct DESC;` |
| Merge | Merge (append) | Combines monthly and exception rows. Not used downstream. |
| Build Report | Code (JavaScript) | Validates both inputs, builds the report text and an INSERT statement. Error output enabled. |
| Log Run | PostgreSQL, Execute Query | Saves the successful run into `analytics.report_log` with `ai_status = skipped` |
| Build AI Input | Code (JavaScript) | Builds the payload and reconciles monthly totals to the KPIs |
| Mock AI | Code (JavaScript) | Fixed template filled from payload values. Not AI. |
| Check AI Output | Code (JavaScript) | Checker copy. Keeps the mock status and never stores rejected text. |
| Log AI Result | PostgreSQL, Execute Query | Updates the logged row with `ai_status`, `ai_summary`, `ai_check_detail` |
| Prepare Failure Log | Code (JavaScript) | Turns the error message into an INSERT statement |
| Log Failure | PostgreSQL, Execute Query | Saves the failed run into `analytics.report_log` |

## Exception rule (sql/06_exceptions.sql)
A shipping mode is an exception when its delay rate is above the overall delay rate and it has at least 500 eligible orders. These thresholds are a documented decision and can be changed.

## Run log (sql/07_run_log.sql, sql/09_report_log_ai.sql)
Table `analytics.report_log`: run id, time, status (`success` or `failed`), key KPI values, exception count, the report text (or the error message for failed runs), and the AI fields `ai_status`, `ai_summary`, `ai_check_detail`.

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
| Normal run succeeds | Passed. All nodes ran and Build Report returned `validation: passed`. |
| KPI values match SQL | Passed. 65,752 orders, 62,897 eligible, 2,855 excluded, 26,849 on time (42.69%), 36,048 late (57.31%), 3.50 average order-to-ship days. |
| Output has KPI summary and exceptions | Passed. First Class: 9,602 late of 9,602 eligible (100.00%). Second Class: 9,803 late of 12,256 eligible (79.99%). |
| Successful run is logged | Passed. Rows with status `success` and the same totals were found in `analytics.report_log` with a database query. |
| Broken input is rejected visibly | Passed. The KPI query was temporarily changed to return eligible orders + 100. Build Report failed with: "eligible + excluded does not equal total orders; on-time + late does not equal eligible orders; delay rate does not match late / eligible". No report was produced. The real query was restored afterwards. |
| Failed run is logged | Passed. The same test left a row with status `failed`, empty totals, and the error message as its text. |
| AI uses only supplied metrics | Passed with the MOCK only. An invented number (run 12) and an invented cause (run 13) were rejected, and the rejected text was not stored. Real AI model: NOT TESTED. Details: `docs/ai_layer.md`. |

## Failure path
- **Validation fails:** Build Report sends the error down its error output. Prepare Failure Log and Log Failure save it as a `failed` row, and no report is produced. Fix the data or the SQL view, then run again.
- **Database unreachable or a query fails in Get KPIs, Get Monthly or Get Exceptions:** the run stops before Build Report. **Not tested.**
- **Log Run or Log Failure fails to write:** **Not tested.**
- **AI branch fails after Log Run:** the KPI row stays logged with `ai_status = skipped`. **Not tested.**
- **Email or Slack alert:** not set up. Failures are visible in n8n and in `analytics.report_log`.

## Setup
1. Run the SQL scripts in `sql/` in order (01 to 09).
2. In n8n, create a Postgres credential named `Postgres account`: host `localhost`, database `supply_chain`, user `postgres`, port 5432, SSL disabled. Enter the password in n8n only. The export does not contain it.
3. Import `n8n/KPI Report.json` into n8n and run it.
4. Run n8n in its own Command Prompt window and leave it open.

## Updating the export
1. Save the workflow in n8n.
2. Run `n8n export:workflow --id=<workflow id> --output="n8n\KPI Report.json"`. It can take a minute with no output. Do not press Ctrl+C.
3. Run `python python\sanitize_n8n_export.py` to remove personal fields and format the file.
4. Check the file for secrets before committing.

## Known limits
- Manual trigger only, no schedule.
- The report is stored in the database but not sent to anyone.
- The log contains the test runs from development.
- Report times are in UTC.
- The AI step is a mock template. No real AI model has been run.