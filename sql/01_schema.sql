-- 01_schema.sql: create the three layers and the raw landing table.
-- Run against the supply_chain database. Safe to re-run.

CREATE SCHEMA IF NOT EXISTS raw;        -- landing copy of orders_clean.csv, all TEXT
CREATE SCHEMA IF NOT EXISTS staging;    -- typed, validated tables
CREATE SCHEMA IF NOT EXISTS analytics;  -- views and KPIs used by Power BI

DROP TABLE IF EXISTS raw.orders;

-- Column order must match the CSV header exactly (needed for COPY).
CREATE TABLE raw.orders (
    type                         TEXT,
    days_for_shipping_real       TEXT,
    days_for_shipment_scheduled  TEXT,
    delivery_status              TEXT,
    late_delivery_risk           TEXT,
    category_id                  TEXT,
    category_name                TEXT,
    customer_city                TEXT,
    customer_country             TEXT,
    customer_id                  TEXT,
    customer_segment             TEXT,
    customer_state               TEXT,
    customer_zipcode             TEXT,
    department_id                TEXT,
    department_name              TEXT,
    latitude                     TEXT,
    longitude                    TEXT,
    market                       TEXT,
    order_city                   TEXT,
    order_country                TEXT,
    order_customer_id            TEXT,
    order_date                   TEXT,
    order_id                     TEXT,
    order_item_cardprod_id       TEXT,
    order_item_discount          TEXT,
    order_item_discount_rate     TEXT,
    order_item_id                TEXT,
    order_item_product_price     TEXT,
    order_item_profit_ratio      TEXT,
    order_item_quantity          TEXT,
    sales                        TEXT,
    order_item_total             TEXT,
    order_profit_per_order       TEXT,
    order_region                 TEXT,
    order_state                  TEXT,
    order_status                 TEXT,
    product_card_id              TEXT,
    product_category_id          TEXT,
    product_image                TEXT,
    product_name                 TEXT,
    product_price                TEXT,
    shipping_date                TEXT,
    shipping_mode                TEXT,
    is_late                      TEXT,
    is_eligible                  TEXT,
    is_on_time                   TEXT,
    order_to_ship_days           TEXT
);