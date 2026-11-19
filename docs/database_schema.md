# Database Schema

## 1. Overview

The **NYC Urban Services, Incidents & Spatial Analysis** project uses PostgreSQL with the PostGIS extension to store, process, and analyze spatial and non-spatial datasets.

The database is named `nyc_urban` and is organized into three primary schemas:

- `raw` — imported source datasets.
- `core` — cleaned and standardized datasets prepared for analysis.
- `analysis` — derived datasets produced through spatial and statistical operations.

This structure separates source data from processed datasets and analytical results, making the workflow easier to maintain, reproduce, and inspect.

## 2. Database Architecture

The database follows a staged data-processing architecture:

```text
                  SOURCE DATASETS
                        |
                        v
                  +-----------+
                  |    raw    |
                  +-----------+
                        |
                        v
               Cleaning and Quality Control
                        |
                        v
                  +-----------+
                  |   core    |
                  +-----------+
                        |
                        v
                Spatial and Statistical
                      Analysis
                        |
                        v
                  +-----------+
                  |  analysis |
                  +-----------+
                        |
                        v
                SQL Outputs and QGIS
                  Visualization
```

Each schema has a distinct responsibility.

### 2.1 `raw`

The `raw` schema contains source datasets imported into PostgreSQL.

Its purpose is to preserve the original source information before applying project-specific cleaning, standardization, or spatial processing.

Source datasets may include spatial tables, non-spatial tables, and attributes retained for later processing.

The raw schema also contains source data that may not be incorporated into the final analytical workflow. For example, `raw.fire_odm` contains origin-destination cost records that were retained but not integrated into the principal firehouse proximity analysis.

### 2.2 `core`

The `core` schema contains the cleaned and standardized datasets used as the primary inputs for analysis.

The principal tables are:

| Table | Description | Geometry |
|---|---|---|
| `core.incidents` | NYC 311 service requests for 2021, with standardized identifiers, timestamps, parcel identifiers, and incident locations. | Point |
| `core.firehouses` | FDNY firehouse locations. | Point |
| `core.parcels` | NYC MapPLUTO tax parcels and associated land-use and building attributes. | MultiPolygon |
| `core.pharmacies` | Recorded Rite Aid pharmacy locations used in the proximity analysis. | Spatial attributes retained in the prepared dataset. |
| `core.weather_stations` | Weather-station observations retained in the database. | Refer to the actual table schema for geometry details. |

The core schema provides a consistent foundation for spatial operations and attribute-based joins.

### 2.3 `analysis`

The `analysis` schema contains derived datasets created from the core tables.

These tables store the results of spatial aggregation, proximity calculations, parcel-level incident integration, and summary analysis.

| Table | Description | Geometry |
|---|---|---|
| `analysis.incident_hotspots` | Incident counts aggregated into occupied 1,000 ft × 1,000 ft grid cells. | Polygon |
| `analysis.integrated_hotspot_profiles` | Hotspot density attributes combined with nearest-firehouse information and distance measurements. | Polygon |
| `analysis.distant_high_density_hotspots` | High-density hotspot cells located more than one mile from their nearest firehouse. | Polygon |
| `analysis.firehouse_hotspot_profiles` | Aggregated profiles of high-density hotspots grouped by nearest firehouse. | Refer to the actual table schema. |
| `analysis.parcel_incident_profiles` | Parcel-level incident counts and complaint and agency summaries. | MultiPolygon |
| `analysis.parcel_pharmacy_accessibility` | Parcel-level incident information combined with distance to the nearest recorded Rite Aid location. | MultiPolygon |
| `analysis.parcel_firehouse_accessibility` | Parcel-level distance to the nearest FDNY firehouse. | MultiPolygon |
| `analysis.density_firehouse_distance_summary` | Summary statistics comparing hotspot density classes and nearest-firehouse distances. | Non-spatial summary table. |

The analysis schema is designed to provide reusable outputs for statistical assessment and cartographic visualization in QGIS.

## 3. Key Data Relationships

The principal relationships between datasets are established through a combination of attribute-based joins and spatial operations.

### 3.1 Incidents and Parcels

The primary relationship between NYC 311 incidents and MapPLUTO parcels is established through the **BBL (Borough-Block-Lot)** identifier.

```text
core.incidents
      |
      | BBL
      |
      v
core.parcels
      |
      v
analysis.parcel_incident_profiles
```

Incident records with a valid BBL are associated with parcels using this identifier.

Additional spatial assignment is applied to eligible incidents without a usable BBL, where their valid point geometry allows them to be assigned to a parcel.

The resulting parcel-level dataset contains incident counts, complaint-type counts, agency counts, and temporal summaries.

Not all incidents can be linked to a parcel. Missing or invalid geometries, absent BBL values, and unmatched parcel identifiers are retained as data-quality limitations.

### 3.2 Incidents and Hotspot Grid

Incident locations are spatially aggregated into a regular grid of 1,000 ft × 1,000 ft cells.

```text
core.incidents
      |
      | Spatial aggregation
      v
analysis.incident_hotspots
      |
      v
Incident-density classification
```

Each occupied grid cell stores its incident count and associated density classification.

The grid provides a consistent spatial unit for comparing incident concentration across the study area.

### 3.3 Firehouses and Hotspots

The nearest FDNY firehouse is identified for each hotspot cell using spatial nearest-neighbor analysis.

```text
analysis.incident_hotspots
             |
             | Nearest-neighbor analysis
             |
             v
      core.firehouses
             |
             v
analysis.integrated_hotspot_profiles
             |
             +-----------------------------+
             |                             |
             v                             v
analysis.distant_high_density_     analysis.firehouse_hotspot_
hotspots                           profiles
```

The integrated dataset combines hotspot attributes with the identity and straight-line distance of the nearest firehouse.

It is subsequently used to identify high-density hotspot cells located more than one mile from the nearest firehouse and to summarize high-density hotspot patterns by firehouse.

### 3.4 Parcels and Firehouses

Each parcel is associated with its nearest FDNY firehouse through spatial nearest-neighbor analysis.

```text
core.parcels
      |
      | Nearest-neighbor analysis
      |
      v
core.firehouses
      |
      v
analysis.parcel_firehouse_accessibility
```

The resulting dataset stores the nearest firehouse information and the corresponding straight-line distance in feet and miles.

### 3.5 Parcels and Pharmacies

The pharmacy analysis combines parcel and incident information with the nearest recorded Rite Aid location.

```text
core.parcels
      |
      +----------------------+
      |                      |
      | BBL                  | Spatial proximity
      |                      |
      v                      v
analysis.parcel_       core.pharmacies
incident_profiles            |
      |                      |
      +----------+-----------+
                 |
                 v
analysis.parcel_pharmacy_accessibility
```

The resulting dataset includes parcel attributes, incident counts, nearest pharmacy information, and straight-line distance in miles.

The pharmacy dataset represents the recorded Rite Aid locations included in this project, not all pharmacies or healthcare facilities in New York City.

## 4. Spatial Reference System

The principal spatial datasets use:

**EPSG:2263 — NAD83 / New York Long Island (US survey feet)**

This projected coordinate reference system is used for spatial operations and distance calculations in the NYC study area.

Using a projected coordinate system with feet as its linear unit allows distances to be calculated consistently and converted to miles when required.

The project uses PostGIS spatial functions and spatial indexing to support geometric operations and nearest-neighbor queries.

## 5. Database Processing Workflow

The database processing workflow is divided into sequential stages.

| Stage | Directory | Purpose |
|---|---|---|
| Database setup | `sql/00_setup/` | Enable required extensions and create database schemas. |
| Data ingestion | `sql/01_ingestion/` | Import source datasets into the database. |
| Quality control | `sql/02_quality_control/` | Inspect data completeness, geometry validity, identifiers, and other quality issues. |
| Core preparation | `sql/03_core/` | Clean and standardize source datasets into the core schema. |
| Spatial analysis | `sql/04_analysis/` | Perform spatial integration, aggregation, proximity analysis, and statistical processing. |
| Output preparation | `sql/05_outputs/` | Prepare final analytical datasets for visualization and reporting. |

The stages are designed to keep data preparation separate from analytical processing and final presentation.

## 6. Spatial and Database Technologies

The project uses the following database technologies and spatial capabilities:

- **PostgreSQL:** Relational database management and SQL-based data processing.
- **PostGIS:** Storage, querying, and processing of spatial geometries.
- **Spatial indexing:** Supports efficient spatial queries and geometric operations.
- **Nearest-neighbor queries:** Used to identify the closest firehouse or pharmacy to spatial features.
- **Attribute-based joins:** Used to connect datasets through identifiers such as BBL.
- **Spatial operations:** Used for point-in-polygon assignment, grid aggregation, and proximity analysis.

The final analytical tables are connected to QGIS for thematic mapping, cartographic layout production, and visualization.

## 7. Reproducibility and Maintenance

The separation of raw, core, and analysis schemas provides several advantages:

- Source datasets remain separate from processed data.
- Cleaning and quality-control operations can be inspected independently.
- Analytical outputs can be regenerated from prepared core datasets.
- Intermediate and final analytical tables can be reused by multiple outputs.
- QGIS visualizations can connect directly to the database rather than relying exclusively on exported intermediate files.

SQL scripts are organized by processing stage to make the workflow easier to follow and reproduce.

For field-level descriptions and data-quality details, refer to [`data_dictionary.md`](data_dictionary.md). For the analytical procedures and assumptions, refer to [`methodology.md`](methodology.md).