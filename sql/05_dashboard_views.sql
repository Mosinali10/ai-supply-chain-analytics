-- 05_dashboard_views.sql: line-level view for category analysis. Safe to re-run.
DROP VIEW IF EXISTS analytics.fact_order_lines;

CREATE VIEW analytics.fact_order_lines AS
SELECT
    order_item_id,
    order_id,
    category_name,
    product_name,
    shipping_mode,
    market,
    customer_segment,
    is_eligible,
    is_late,
    order_item_quantity,
    order_item_total
FROM staging.orders;