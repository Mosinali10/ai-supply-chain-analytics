from pathlib import Path
import pandas as pd
ROOT = Path(__file__).resolve().parent.parent
RAW_FILE = ROOT / "data" / "raw" / "DataCoSupplyChainDataset.csv"

df=pd.read_csv(RAW_FILE,encoding = "latin-1")

print("Raws:",len(df))
print("Columns",df.shape[1])

summary = pd.DataFrame(
    {
        "dtype":df.dtypes.astype(str),
        "nulls":df.isna().sum(),
        "distinct":df.nunique(),
    }
)

print(summary.to_string())

for col in ["Type","Delivery Status","Late_delivery_risk","Order Status","Shipping Mode"]:
    print("\n--",col,"--")
    print(df[col].value_counts(dropna=False))

# ---- 4. Do the three "late" signals agree? ----
print("\n== Delivery Status vs Late_delivery_risk ==")
print(pd.crosstab(df["Delivery Status"], df["Late_delivery_risk"]))

real_gt_sched = df["Days for shipping (real)"] > df["Days for shipment (scheduled)"]
print("\n== Delivery Status vs (real days > scheduled days) ==")
print(pd.crosstab(df["Delivery Status"], real_gt_sched))

# ---- 5. Which orders are eligible? Compare the two status columns ----
print("\n== Order Status vs Delivery Status ==")
print(pd.crosstab(df["Order Status"], df["Delivery Status"]))

# ---- 6. Dates: look at the raw text first, then parse ----
order_col = "order date (DateOrders)"
ship_col = "shipping date (DateOrders)"
print("\n== Date samples (raw text) ==")
print(df[order_col].head(3).tolist())
print(df[ship_col].head(3).tolist())

order_dt = pd.to_datetime(df[order_col], errors="coerce")
ship_dt = pd.to_datetime(df[ship_col], errors="coerce")
print("\nOrder date  -> failed to parse:", order_dt.isna().sum(), "| min:", order_dt.min(), "| max:", order_dt.max())
print("Ship date   -> failed to parse:", ship_dt.isna().sum(), "| min:", ship_dt.min(), "| max:", ship_dt.max())

gap_days = (ship_dt - order_dt).dt.total_seconds() / 86400
print("\nShipping date minus order date (days):")
print(gap_days.describe().round(2))
print("Shipping BEFORE order date:", (gap_days < 0).sum())
print("Gap (rounded) equals 'Days for shipping (real)':", (gap_days.round() == df["Days for shipping (real)"]).sum())

# ---- 7. Numeric ranges: look for impossible values ----
print("\n== Numeric ranges ==")
num_cols = ["Days for shipping (real)", "Days for shipment (scheduled)", "Order Item Quantity",
            "Sales", "Order Item Total", "Order Item Discount", "Order Item Discount Rate",
            "Order Item Product Price", "Benefit per order"]
print(df[num_cols].describe().round(2).T.to_string())

# ---- 8. Are similar-looking columns actually identical? ----
print("\n== Duplicate-column checks ==")
print("Sales per customer == Order Item Total:", (df["Sales per customer"] == df["Order Item Total"]).all())
print("Benefit per order == Order Profit Per Order:", (df["Benefit per order"] == df["Order Profit Per Order"]).all())