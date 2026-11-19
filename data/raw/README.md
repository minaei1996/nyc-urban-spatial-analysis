# Raw Data

## Overview

This directory contains the source datasets required to reproduce the **NYC Urban Services, Incidents & Spatial Analysis** project.

**Raw datasets are not stored or committed in this GitHub repository.** They are distributed separately to keep the repository lightweight and avoid version-controlling large source files.

## Download

All required source datasets are available from the following download page:

**[Download Project Raw Data](https://loc8.cc/sql/data)**

Download the datasets and place them in this directory while preserving their original filenames and directory structure.

## Source Data Inventory

The project uses the following source datasets:

| Dataset | Format | Description / Purpose |
|---|---|---|
| `ACS_2021_5YR_BG_36_NEW_YORK.gdb` | File Geodatabase | American Community Survey 2021 five-year estimates at the census block group level for New York. |
| `nyc_mappluto_22v3_shp` | Shapefile dataset | NYC MapPLUTO parcel boundaries and associated land-use and building attributes. |
| `ZIP_CODE_040114` | Shapefile dataset | NYC ZIP Code Tabulation Area / ZIP code geographic boundaries. |
| `FDNY_Firehouse_Listing.csv` | CSV | FDNY firehouse listing and location attributes. |
| `fire_odm.csv` | CSV | Fire-related origin-destination cost records. |
| `nyc_311.csv` | CSV | NYC 311 service-request records used for the 2021 incident analysis. |
| `nys_mesonet_202307.csv` | CSV | New York State Mesonet weather-station observations from July 2023. |
| `rite_aid_odm.csv` | CSV | Rite Aid location and associated origin-destination records. |

## Local Directory Structure

After downloading and extracting the source data, the directory should contain:

```text
data/
└── raw/
    ├── ACS_2021_5YR_BG_36_NEW_YORK.gdb/
    ├── nyc_mappluto_22v3_shp/
    ├── ZIP_CODE_040114/
    ├── FDNY_Firehouse_Listing.csv
    ├── fire_odm.csv
    ├── nyc_311.csv
    ├── nys_mesonet_202307.csv
    └── rite_aid_odm.csv
```

Keep the original filenames and directory names unchanged unless the corresponding ingestion scripts are updated.

## Important Notes

- The raw datasets are intentionally excluded from Git version control.
- Do not upload raw datasets to this repository.
- The source data must be downloaded separately before executing the ingestion workflow.
- Some datasets have different temporal coverage. In particular, the weather observations cover July 2023, while the primary 311 incident analysis covers 2021.
- Not every source dataset is necessarily incorporated into the final analytical outputs.

For data preparation procedures and the role of each dataset in the analytical workflow, refer to [`../../docs/methodology.md`](../../docs/methodology.md).

For field definitions and dataset descriptions, refer to [`../../docs/data_dictionary.md`](../../docs/data_dictionary.md).