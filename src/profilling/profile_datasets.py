from pathlib import Path
import pandas as pd


DATA_DIR = Path("data/raw")


FILES = [
    "FDNY_Firehouse_Listing.csv",
    "nyc_311.csv",
    "nys_mesonet_202307.csv",
    "rite_aid_odm.csv",
]


def profile_file(path: Path) -> None:
    print("\n" + "=" * 80)
    print(f"FILE: {path.name}")
    print("=" * 80)

    df = pd.read_csv(path, low_memory=False)

    print(f"Rows: {len(df):,}")
    print(f"Columns: {len(df.columns)}")

    print("\nColumns:")
    for column in df.columns:
        print(f"  - {column}")

    print("\nData types:")
    print(df.dtypes.to_string())

    print("\nNull counts:")
    print(df.isna().sum().to_string())

    print("\nFirst 3 rows:")
    print(df.head(3).to_string())


def main() -> None:
    for filename in FILES:
        path = DATA_DIR / filename

        if not path.exists():
            print(f"\nWARNING: File not found: {path}")
            continue

        profile_file(path)


if __name__ == "__main__":
    main()