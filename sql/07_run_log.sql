-- 07_run_log.sql: one row per n8n run. Safe to re-run (never drops existing rows).
CREATE TABLE IF NOT EXISTS analytics.report_log (
    run_id          SERIAL PRIMARY KEY,
    run_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    status          TEXT NOT NULL,          -- 'success' or 'failed'
    total_orders    INTEGER,
    eligible_orders INTEGER,
    late_orders     INTEGER,
    delay_rate_pct  NUMERIC,
    exception_count INTEGER,
    report_text     TEXT,                   -- the report, or the error message when failed
    CONSTRAINT report_log_status_check CHECK (status IN ('success', 'failed'))
);