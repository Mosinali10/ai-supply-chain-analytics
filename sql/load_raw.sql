-- load_raw.sql: copy data/processed/orders_clean.csv into raw.orders.
-- TRUNCATE first, so re-running never creates duplicate rows.
TRUNCATE raw.orders;

-- \copy must stay on ONE line.
\copy raw.orders FROM 'E:/Projects/ai-supply-chain-analytics/data/processed/orders_clean.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
