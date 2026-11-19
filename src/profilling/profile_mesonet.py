from pathlib import Path
import pandas as pd


path = Path("data/raw/nys_mesonet_202307.csv")

df = pd.read_csv(path)

lat = df["latitude [degrees_north]"]
lon = df["longitude [degrees_east]"]

print("=" * 80)
print("NYS MESONET")
print("=" * 80)

print(f"Rows: {len(df):,}")
print(f"Stations: {df['station'].nunique():,}")

print("\nDate range:")
print(df["time_end"].min())
print(df["time_end"].max())

print("\nLatitude:")
print(f"  Min: {lat.min()}")
print(f"  Max: {lat.max()}")

print("\nLongitude:")
print(f"  Min: {lon.min()}")
print(f"  Max: {lon.max()}")

print("\nStations:")
stations = (
    df.groupby("station")
    .agg(
        latitude=("latitude [degrees_north]", "first"),
        longitude=("longitude [degrees_east]", "first"),
        records=("station", "size")
    )
    .sort_values("station")
)

print(stations.to_string())