CREATE OR REPLACE VIEW analytics.monthly_delay AS
SELECT
    DATE_TRUNC('month', order_date)::date AS order_month,
    COUNT(DISTINCT order_id) FILTER (WHERE is_eligible = 1) AS eligible_orders,
    COUNT(DISTINCT order_id) FILTER (WHERE is_eligible = 1 AND is_late = 1) AS late_orders,
    ROUND(
        100.0 * COUNT(DISTINCT order_id) FILTER (WHERE is_eligible = 1 AND is_late = 1)
        / NULLIF(COUNT(DISTINCT order_id) FILTER (WHERE is_eligible = 1), 0),
        2
    ) AS delay_rate_pct
FROM analytics.fact_orders
GROUP BY DATE_TRUNC('month', order_date)::date
ORDER BY order_month;