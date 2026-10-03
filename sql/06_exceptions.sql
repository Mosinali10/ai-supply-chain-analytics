-- 06_exceptions.sql: exception list used by the n8n report. Safe to re-run.
-- Rule (documented decision): a shipping mode is an EXCEPTION when
--   (1) its delay rate is above the overall delay rate, and
--   (2) it has at least 500 eligible orders (avoids alerts on tiny samples).
-- Thresholds are adjustable.
DROP VIEW IF EXISTS analytics.exceptions_shipping_mode;

CREATE VIEW analytics.exceptions_shipping_mode AS
SELECT
    shipping_mode,
    sum(is_eligible)                                         AS eligible_orders,
    sum(is_late)                                             AS late_orders,
    round(100.0 * sum(is_late) / sum(is_eligible), 2)        AS delay_rate_pct,
    round(100.0 * sum(is_late) / sum(is_eligible)
          - (SELECT delay_rate_pct FROM analytics.kpi_summary), 2) AS points_above_overall
FROM analytics.fact_orders
GROUP BY shipping_mode
HAVING sum(is_eligible) >= 500
   AND 100.0 * sum(is_late) / sum(is_eligible)
       > (SELECT delay_rate_pct FROM analytics.kpi_summary);