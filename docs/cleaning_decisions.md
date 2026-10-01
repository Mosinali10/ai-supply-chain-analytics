# Cleaning and Rule Decisions

Source: DataCo Smart Supply Chain (Kaggle copy, original on Mendeley Data).
All facts below come from `python/01_profile.py`. The raw file is never modified.

## Dataset facts
- 180,519 rows, 53 columns. One row per order line (`Order Item Id` is unique).
- 65,752 distinct `Order Id`, so Total Orders must use `COUNT(DISTINCT order_id)`.
- Encoding is not UTF-8, so the file is read with `latin-1`.
- Dates are month/day/year with a time. All parse; no shipping date is before its order date.

## Decisions
**D1. Delay rule.** A line is late if `Delivery Status = "Late delivery"`.
Evidence: identical to `Late_delivery_risk = 1` on every row, and to real days > scheduled days on every non-canceled row.

**D2. Eligible lines.** Exclude `Delivery Status = "Shipping canceled"` from all delivery KPIs.
Evidence: those 7,754 lines are exactly `Order Status` CANCELED (3,692) + SUSPECTED_FRAUD (4,062). Eligible lines: 172,765.

**D3. Cycle time.** Use `Days for shipping (real)`, whole days, labeled "order-to-ship days".
Evidence: equals the shipping-date minus order-date gap on 175,862 rows. The other 4,657 rows all have a 12-hour gap recorded as 1 day. There is no delivery date, so this is not delivery time.

**D4. Columns dropped from the processed layer.**
- `Product Description` (100% null), `Order Zipcode` (86% null), `Product Status` (one value only).
- `Customer Email`, `Customer Password` (one value each; personal data).
- `Customer Fname`, `Customer Lname`, `Customer Street` (personal data, not needed for any KPI).
- `Sales per customer` (identical to `Order Item Total`) and `Benefit per order` (identical to `Order Profit Per Order`).

## KPIs unavailable from this dataset
- In-Full % and OTIF: there is no delivered-quantity column (only `Order Item Quantity`).
- Supplier KPIs: there is no supplier column.
- True delivery cycle time: there is no delivery date.

## Decisions from SQL analysis (sql/04_analysis.sql)

**D5. Order Value = `order_item_total`** (sales minus discount).
Evidence: it equals sales minus discount on 179,295 of 180,519 lines. The other 1,224 differ by exactly 0.01 (rounding). Total value: 33,054,402.38. `sales` (36,784,735.01) is the price before discount and is not used as Order Value.

**D6. KPIs are calculated at order level (`order_id`).**
Evidence: no order has lines with different delivery status or shipping date (0 of 65,752).
Result: 65,752 orders; 62,897 eligible; 36,048 late; delay rate 57.31%. The line-level late rate is 57.29% (98,977 of 172,765 lines). Order-level total value matches line-level (33,054,402.38).

## Findings to verify before publishing
- First Class: all 26,513 eligible lines are late. Scheduled 1 day, real always 2 days.
- Same Day: all 4,454 late lines have scheduled 0 and real 1. This count equals the half-day (12-hour) cases found earlier; a row-level match has not been tested.
- Standard and Second Class: late exactly when real days exceed scheduled days.
- Real shipping days are spread almost evenly across 2-6 days for Standard and Second Class, which is unusual for real operations. The data may be simulated; treat shipping-mode findings with care.

## Open items
- `Benefit per order` goes as low as -4,274.98. Check whether these are real losses.
- 203 canceled lines also have the half-day gap; the reason is unknown.