# KPI Definitions

Source view: `analytics.fact_orders` (one row per order) and `analytics.kpi_summary`.
SQL: `sql/03_kpis.sql`. Rules and evidence: `docs/cleaning_decisions.md`.

**Grain:** one row per order (`order_id`), 65,752 orders.
**Eligible order:** `is_eligible = 1`, meaning delivery status is not "Shipping canceled" (rule D2).
**Late order:** delivery status is "Late delivery" (rule D1).

## Verified values (all orders, Jan 2015 - Jan 2018)

| KPI | Formula | Numerator | Denominator | Value |
|---|---|---|---|---|
| Total Orders | `COUNT(DISTINCT order_id)` | n/a | n/a | 65,752 |
| Total Order Value | `SUM(order_item_total)` | n/a | n/a | 33,054,402.38 |
| Excluded canceled orders | orders with `is_eligible = 0` | n/a | n/a | 2,855 |
| Eligible orders | `SUM(is_eligible)` | n/a | n/a | 62,897 |
| On-Time % | on-time orders / eligible orders x 100 | 26,849 | 62,897 | 42.69% |
| Delay Rate % | late orders / eligible orders x 100 | 36,048 | 62,897 | 57.31% |
| Avg Order-to-Ship Days | `AVG(days_for_shipping_real)` over eligible orders | n/a | n/a | 3.50 days |

On-Time % and Delay Rate % add up to 100%, because every eligible order is either on time (advance shipping or shipping on time) or late.

## Rules behind each KPI
- **Total Order Value** uses `order_item_total` (sales minus discount), not `sales` (D5). Total sales before discount is 36,784,735.01, and it is not used.
- **Avg Order-to-Ship Days** measures order date to shipping date. The dataset has no delivery date, so it is not delivery time (D3).
- **Percentages** are calculated at order level. The line-level delay rate is 57.29% (98,977 of 172,765 lines).
- **Excluded orders** are reported next to the percentages, so the denominator is visible.

## Unavailable KPIs (dataset limits)
| KPI from the PRD | Status | Reason |
|---|---|---|
| In-Full % | Unavailable | No delivered-quantity column |
| OTIF % | Unavailable | Needs In-Full |
| Supplier KPIs | Unavailable | No supplier column |
| True cycle time (order to delivery) | Unavailable | No delivery date |

## Reconciliation
SQL totals are the reference values. The Power BI dashboard must reproduce every value in the table above.