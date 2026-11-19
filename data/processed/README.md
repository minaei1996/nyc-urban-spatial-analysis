# Processed Data

## Overview

This directory is reserved for processed datasets generated during the project workflow.

Unlike the raw source datasets, processed data are primarily managed within the PostgreSQL/PostGIS database rather than distributed as standalone files.

The database separates processed data into two main schemas:

- **`core`** — cleaned and standardized datasets prepared for analysis.
- **`analysis`** — derived datasets containing spatial and statistical analysis results.

## Processing Workflow

Processed datasets are generated through the SQL scripts organized in the repository:

| Directory | Purpose |
|---|---|
| `sql/02_quality_control/` | Data validation and quality-control checks. |
| `sql/03_core/` | Creation and preparation of standardized core datasets. |
| `sql/04_analysis/` | Spatial integration, proximity calculations, and statistical analysis. |
| `sql/05_outputs/` | Preparation of final analytical outputs. |

The resulting tables are stored in the `nyc_urban` PostgreSQL database.

## Generated Datasets

The principal processed datasets include:

- Cleaned NYC 311 incident records.
- Standardized FDNY firehouse locations.
- NYC MapPLUTO parcel records.
- Prepared Rite Aid pharmacy locations.
- Parcel-level incident profiles.
- Incident hotspot grid cells.
- Integrated hotspot and firehouse proximity profiles.
- Parcel-to-firehouse and parcel-to-pharmacy proximity datasets.

For a complete description of these datasets, their fields, and their analytical roles, refer to [`../../docs/data_dictionary.md`](../../docs/data_dictionary.md).

## Storage and Version Control

Processed database tables are generated through the project's SQL workflow and are not maintained as separate copies in this directory.

This avoids unnecessary duplication of large datasets and keeps the repository focused on source code, SQL scripts, documentation, and final presentation outputs.

The `data/processed/` directory is therefore retained for organizational purposes and future use when standalone processed-data exports are needed.