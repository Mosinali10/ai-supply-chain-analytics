"""
02_clean.py - Phase 3: build the processed layer from the RAW file.
Raw data is only read, never modified. Decisions D1-D4: docs/cleaning_decisions.md
"""
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
RAW_FILE = ROOT / "data" / "raw" / "DataCoSupplyChainDataset.csv"
OUT_FILE = ROOT / "data" / "processed" / "orders_clean.csv"
LOG_FILE = ROOT / "docs" / "cleaning_log.txt"

log = []


def note(text):
    """Print a line and keep it for the saved log."""
    print(text)
    log.append(text)


# 1. Load the raw file (read-only)
df = pd.read_csv(RAW_FILE, encoding="latin-1")
rows_in = len(df)
note(f"Loaded raw: {rows_in:,} rows, {df.shape[1]} columns")

# 2. Decision D4: drop empty, constant, duplicate and personal-data columns
DROP_COLS = [
    "Product Description", "Order Zipcode", "Product Status",
    "Customer Email", "Customer Password",
    "Customer Fname", "Customer Lname", "Customer Street",
    "Sales per customer", "Benefit per order",
]
df = df.drop(columns=DROP_COLS)
note(f"Dropped {len(DROP_COLS)} columns (D4)")

# 3. Standardize column names to snake_case
df.columns = (
    df.columns.str.strip()
    .str.lower()
    .str.replace(r"[^0-9a-z]+", "_", regex=True)
    .str.strip("_")
)
df = df.rename(
    columns={
        "order_date_dateorders": "order_date",
        "shipping_date_dateorders": "shipping_date",
    }
)

# 4. Trim stray spaces in text columns
for col in df.columns:
    if pd.api.types.is_string_dtype(df[col]):
        df[col] = df[col].str.strip()

# 5. Parse dates explicitly (month/day/year hour:minute, as seen in profiling)
df["order_date"] = pd.to_datetime(df["order_date"], format="%m/%d/%Y %H:%M")
df["shipping_date"] = pd.to_datetime(df["shipping_date"], format="%m/%d/%Y %H:%M")

# 6. Derived fields (rules D1-D3)
df["is_late"] = (df["delivery_status"] == "Late delivery").astype(int)  # D1
df["is_eligible"] = (df["delivery_status"] != "Shipping canceled").astype(int)  # D2
df["is_on_time"] = df["delivery_status"].isin(["Advance shipping", "Shipping on time"]).astype(int)
df["order_to_ship_days"] = df["days_for_shipping_real"]  # D3

# 7. Validation checks
note("\nVALIDATION")
all_passed = True


def check(name, passed):
    global all_passed
    passed = bool(passed)
    all_passed = all_passed and passed
    note(f"{'PASS' if passed else 'FAIL'} | {name}")


key_cols = ["order_id", "order_item_id", "order_date", "shipping_date",
            "delivery_status", "sales", "order_item_total"]
check("No rows lost", len(df) == rows_in)
check("order_item_id is unique", df["order_item_id"].is_unique)
check("No nulls in key columns", df[key_cols].isna().sum().sum() == 0)
check("Shipping date never before order date", (df["shipping_date"] >= df["order_date"]).all())
check("is_late matches late_delivery_risk", (df["is_late"] == df["late_delivery_risk"]).all())
check("is_late + is_on_time == is_eligible on every row",
      ((df["is_late"] + df["is_on_time"]) == df["is_eligible"]).all())
check("Eligible lines == 172,765", df["is_eligible"].sum() == 172765)

note(f"\nFinal: {len(df):,} rows, {df.shape[1]} columns")
note(f"Distinct orders: {df['order_id'].nunique():,}")
note(f"Eligible lines: {df['is_eligible'].sum():,} | Late: {df['is_late'].sum():,}")

# 8. Save the log, then export only if every check passed
LOG_FILE.write_text("\n".join(log), encoding="utf-8")
if not all_passed:
    raise SystemExit("Validation FAILED - nothing exported. See docs/cleaning_log.txt")

OUT_FILE.parent.mkdir(parents=True, exist_ok=True)
df.to_csv(OUT_FILE, index=False)
print(f"\nExported: {OUT_FILE}")