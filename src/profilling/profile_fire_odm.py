from pathlib import Path
import pandas as pd


path = Path("data/raw/fire_odm.csv")

df = pd.read_csv(
    path,
    header=None,
    low_memory=False
)

print("=" * 80)
print("FIRE ODM")
print("=" * 80)

print(f"Rows: {len(df):,}")
print(f"Columns: {len(df.columns)}")

print("\nFirst 10 rows:")
print(df.head(10).to_string(index=False, header=False))

print("\nData types:")
print(df.dtypes.to_string())

print("\nNull counts:")
print(df.isna().sum().to_string())

print("\nUnique values in each column:")
for column in df.columns:
    print(f"\nColumn {column}:")
    print(f"  Unique: {df[column].nunique():,}")
    print(f"  Min:    {df[column].min()}")
    print(f"  Max:    {df[column].max()}")