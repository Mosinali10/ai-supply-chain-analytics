# QA Checklist

Run date: 06-10-2026. Status values: PASSED (evidence given), NOT TESTED, or NOTE.

| # | Check | Status | Evidence |
|---|---|---|---|
| 1 | Raw data unchanged | PASSED (from QA time) | Raw files are not tracked by git. SHA256 of `DataCoSupplyChainDataset.csv` at QA time: `fa6d022ed437155e1a2f0378710602848703c8a7f203f7ff5d77805bf8480aa6`. This detects changes after this date. It does not prove a match with the original download. |
| 2 | Cleaning reproducible | NOT TESTED | Scripts exist (`python/02_clean.py`). A fresh rebuild was not run. |
| 3 | Business keys checked | NOT TESTED | Order-level grain checked in `docs/cleaning_decisions.md` (D6: 0 of 65,752 orders with mixed status). Duplicate-key checks not re-run in QA. |
| 4 | Date calculations tested | PASSED | On 65,752 orders: 0 negative order-to-ship days, 0 NULL, 0 shipped before ordered. Range 0 to 6 days. |
| 5 | KPI denominators correct | PASSED | Build Report checks eligible + excluded = total and on-time + late = eligible (n8n tests). SQL: 62,897 eligible, 36,048 late. |
| 6 | Monthly view reconciles | PASSED | `analytics.monthly_delay`: eligible 62,897, late 36,048. |
| 7 | SQL and Power BI reconcile | PASSED (partly) | Unfiltered pages match SQL: total 65,752, eligible 62,897, on-time 42.69%, delay 57.31%, late 36,048, avg days 3.50. Not compared: total order value, on-time orders count. |
| 8 | Filters behave correctly | NOT TESTED | Filtered pages were only viewed, not verified against SQL. |
| 9 | Automation succeeds | PASSED | Normal run logged (run 10 and later), `status = success`. |
| 10 | Automation fails visibly on bad input | PASSED | Broken KPI input rejected and logged as `failed` (see `docs/n8n_workflow.md`). |
| 11 | Database-down failure path | NOT TESTED | |
| 12 | AI makes no unsupported numeric claims | PASSED with MOCK only | Checker: 8 unit tests passed. Workflow: invented number rejected (run 12), invented cause rejected (run 13), rejected text not stored. |
| 13 | Real AI model | NOT TESTED | No API key. The summary step is a template. |
| 14 | AI-branch `skipped` path | NOT TESTED | |
| 15 | No secrets in repository | PASSED (limited) | Secrets check on committed files printed nothing except instruction text. History search for "password" outside docs and README printed nothing. Other terms were not searched in history. |
| 16 | `.env` and large CSVs not committed | PASSED | `.gitignore` lists `.env` and the CSV paths. `git ls-files data` shows only `.gitkeep` files. |
| 17 | Fresh-clone setup works | NOT TESTED | |
| 18 | README links work | NOT TESTED | |
| 19 | Live deployment works | NOT TESTED | No live page exists yet. |

## Known issues
- Shipping-mode delay patterns are unusually uniform and may reflect how the dataset was built (`docs/kpi_definitions.md`).
- `Benefit per order` goes as low as -4,274.98 and was not investigated.
- The report log holds development test runs.
- `python/03_analysis.py` and `docs/architecture.png` from the PRD structure do not exist yet.