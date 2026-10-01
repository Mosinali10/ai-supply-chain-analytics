-- 03_kpis.sql: order-level fact view and headline KPI view. Safe to re-run.
-- Rules: docs/cleaning_decisions.md (D1 delay, D2 eligible, D3 cycle time, D5 value, D6 grain)

DROP VIEW IF EXISTS analytics.kpi_summary;
DROP VIEW IF EXISTS analytics.fact_orders;

-- One row per order. Verified: these fields never differ between lines of one order.
CREATE VIEW analytics.fact_orders AS
SELECT
    order_id,
    max(customer_id)                              AS customer_id,
    max(customer_segment)                         AS customer_segment,
    max(market)                                   AS market,
    max(order_region)                             AS order_region,
    max(order_country)                            AS order_country,
    max(shipping_mode)                            AS shipping_mode,
    max(order_date)                               AS order_date,
    date_trunc('month', max(order_date))::date    AS order_month,
    max(shipping_date)                            AS shipping_date,
    max(delivery_status)                          AS delivery_status,
    max(is_eligible)                              AS is_eligible,
    max(is_late)                                  AS is_late,
    max(is_on_time)                               AS is_on_time,
    sum(order_item_total)                         AS order_value,
    count(*)                                      AS order_lines,
    sum(order_item_quantity)                      AS units,
    max(days_for_shipment_scheduled)              AS scheduled_days,
    max(days_for_shipping_real)                   AS order_to_ship_days
FROM staging.orders
GROUP BY order_id;

-- Headline KPIs. Percentages use eligible orders (non-canceled) as the denominator.
CREATE VIEW analytics.kpi_summary AS
SELECT
    count(*)                                                          AS total_orders,
    round(sum(order_value), 2)                                        AS total_order_value,
    count(*) FILTER (WHERE is_eligible = 0)                           AS excluded_canceled_orders,
    sum(is_eligible)                                                  AS eligible_orders,
    sum(is_on_time)                                                   AS on_time_orders,
    sum(is_late)                                                      AS late_orders,
    round(100.0 * sum(is_on_time) / sum(is_eligible), 2)              AS on_time_pct,
    round(100.0 * sum(is_late) / sum(is_eligible), 2)                 AS delay_rate_pct,
    round(avg(order_to_ship_days) FILTER (WHERE is_eligible = 1), 2)  AS avg_order_to_ship_days
FROM analytics.fact_orders;