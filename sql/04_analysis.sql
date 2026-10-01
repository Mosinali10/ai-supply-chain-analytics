-- 04_analysis.sql: first analysis queries on staging.orders

-- Q1. Headline numbers
SELECT
    count(DISTINCT order_id)                                  AS total_orders,
    count(*)                                                  AS order_lines,
    round(sum(order_item_total), 2)                           AS value_item_total,
    round(sum(sales), 2)                                      AS value_sales,
    sum(is_eligible)                                          AS eligible_lines,
    round(100.0 * sum(is_late) / sum(is_eligible), 2)         AS late_pct_of_eligible_lines
FROM staging.orders;

-- Q2. Is order_item_total just sales minus discount?
SELECT
    count(*)                                                                         AS lines,
    count(*) FILTER (WHERE abs(sales - order_item_discount - order_item_total) < 0.01)  AS matches,
    count(*) FILTER (WHERE abs(sales - order_item_discount - order_item_total) >= 0.01) AS mismatches
FROM staging.orders;

-- Q3. Late % by shipping mode (eligible lines only)
SELECT
    shipping_mode,
    count(*)                                   AS eligible_lines,
    sum(is_late)                               AS late_lines,
    round(100.0 * sum(is_late) / count(*), 2)  AS late_pct
FROM staging.orders
WHERE is_eligible = 1
GROUP BY shipping_mode
ORDER BY late_pct DESC;

-- Q4. Do lines of the same order ever disagree on status or ship date?
SELECT
    count(*) FILTER (WHERE n_status > 1) AS orders_mixed_status,
    count(*) FILTER (WHERE n_ship > 1)   AS orders_mixed_ship_date
FROM (
    SELECT
        order_id,
        count(DISTINCT delivery_status) AS n_status,
        count(DISTINCT shipping_date)   AS n_ship
    FROM staging.orders
    GROUP BY order_id
) AS per_order;
-- Q5. How big are the 1,224 mismatches?
SELECT
    round(sales - order_item_discount - order_item_total, 2) AS gap,
    count(*)                                                 AS lines
FROM staging.orders
WHERE abs(sales - order_item_discount - order_item_total) >= 0.01
GROUP BY 1
ORDER BY lines DESC
LIMIT 10;

-- Q6. Scheduled vs real shipping days by mode (eligible lines)
SELECT
    shipping_mode,
    days_for_shipment_scheduled AS scheduled_days,
    days_for_shipping_real      AS real_days,
    count(*)                    AS lines
FROM staging.orders
WHERE is_eligible = 1
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

-- Q7. Order-level numbers. No order mixes statuses (Q4), so max() is safe.
WITH per_order AS (
    SELECT
        order_id,
        max(is_eligible)         AS is_eligible,
        max(is_late)             AS is_late,
        sum(order_item_total)    AS order_value
    FROM staging.orders
    GROUP BY order_id
)
SELECT
    count(*)                                              AS total_orders,
    sum(is_eligible)                                      AS eligible_orders,
    sum(is_late)                                          AS late_orders,
    round(100.0 * sum(is_late) / sum(is_eligible), 2)     AS late_pct_of_orders,
    round(sum(order_value), 2)                            AS total_value
FROM per_order;