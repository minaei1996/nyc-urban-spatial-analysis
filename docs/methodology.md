# Methodology

## 1. Overview

This project applies a spatial data engineering and analytical workflow to examine the geographic distribution of NYC 311 service requests, parcel-level incident patterns, and the proximity of urban locations to selected public and commercial facilities.

The analytical workflow integrates multiple spatial datasets within a PostgreSQL/PostGIS environment and uses SQL-based spatial operations to produce reproducible analytical outputs. QGIS is used for spatial visualization, cartographic design, and the preparation of final presentation maps.

The methodology consists of five main stages:

1. Data ingestion and database organization.
2. Data cleaning and quality control.
3. Spatial data integration and preparation.
4. Spatial analysis and statistical assessment.
5. Cartographic visualization and presentation.

## 2. Data Sources and Preparation

The project integrates the following datasets:

| Dataset | Description | Analytical purpose |
|---|---|---|
| NYC 311 Service Requests (2021) | Records of service requests submitted through NYC 311 during 2021 | Incident distribution and hotspot analysis |
| NYC MapPLUTO | Tax-lot and property information for NYC parcels | Parcel-level spatial analysis |
| FDNY Firehouse Locations | Geographic locations and attributes of FDNY firehouses | Firehouse proximity analysis |
| Rite Aid Locations | A dataset containing 100 recorded Rite Aid locations | Pharmacy proximity analysis |

The datasets were imported into PostgreSQL and organized into separate schemas according to their processing stage.

- `raw`: Original imported datasets.
- `core`: Cleaned, standardized, and spatially prepared datasets.
- `analysis`: Derived datasets and analytical results.

This separation maintains the distinction between original source data, prepared spatial data, and analytical outputs.

## 3. Data Cleaning and Quality Control

Before performing spatial analysis, the source datasets underwent validation and preparation.

### 3.1 Geometry Validation

Spatial geometries were inspected for missing or invalid values. Coordinate information was used to construct spatial geometries where necessary.

For the 2021 NYC 311 dataset, 3,214,361 records were imported. Of these, 3,142,352 had valid spatial geometries suitable for spatial analysis. The remaining 72,009 records had missing or invalid geometries and were excluded from geometry-dependent analyses while their original records were retained.

### 3.2 Coordinate Reference System

Spatial datasets were standardized to the projected coordinate reference system EPSG:2263 (NAD83 / New York Long Island).

This projected coordinate system allows spatial measurements and distance calculations to be performed in linear units appropriate for the NYC study area.

### 3.3 Attribute and Record Validation

Additional quality-control procedures included:

- Checking record counts and unique identifiers.
- Identifying duplicate records.
- Inspecting missing and inconsistent attribute values.
- Validating parcel identifiers and geographic relationships.
- Checking the validity of spatial geometries.
- Verifying the consistency of derived analytical outputs.

The 311 incident identifier was retained as the unique record identifier in the prepared dataset.

## 4. Spatial Data Integration

### 4.1 Incident-to-Parcel Association

311 service requests were associated with NYC parcels primarily through the Borough-Block-Lot (BBL) identifier.

Records with valid BBL values were matched against the parcel dataset. For spatially valid incidents without a usable BBL, a spatial assignment procedure was used to associate incidents with parcels based on their geographic locations.

The resulting parcel-level dataset contains aggregated incident information, including:

- Total incident count.
- Number of distinct complaint types.
- Number of reporting agencies.
- First and last recorded incident dates.

The parcel incident profile contains 856,997 parcels. A total of 2,820,963 incidents were successfully associated with parcels through the combined matching procedures.

### 4.2 Incident Hotspot Grid

To examine the spatial concentration of 311 incidents independently of individual parcel boundaries, the study area was represented using a regular grid.

A fishnet grid with cell dimensions of 1,000 ft × 1,000 ft was generated. Spatially valid 311 incidents were assigned to their corresponding grid cells, and incident counts were aggregated for each occupied cell.

This process produced 7,620 occupied grid cells containing all 3,142,352 spatially valid incidents.

The regular grid provides a consistent spatial unit for comparing incident concentrations across different parts of the city.

## 5. Spatial Analysis

### 5.1 Incident Hotspot and Density Analysis

Incident concentration was measured by calculating the number of 311 records within each occupied grid cell.

Because incident counts were highly skewed, density classes were established using empirical percentile thresholds:

- **High:** Incident count at or above the 90th percentile.
- **Very High:** Incident count at or above the 95th percentile.
- **Extreme:** Incident count at or above the 99th percentile.
- **Other:** Cells below the 90th percentile.

These thresholds represent relative statistical classifications within the study dataset rather than official municipal standards.

For additional spatial interpretation, incident counts were converted into an annualized count-per-square-mile equivalent:

`Incident count × 27.8784`

The conversion factor represents the number of 1,000 ft × 1,000 ft cells in one square mile.

This measure is a density-equivalent representation of the recorded annual incident count, not a population-normalized incident rate.

### 5.2 Nearest Firehouse Distance Analysis

The proximity of incidents and parcels to FDNY firehouses was evaluated using nearest-neighbor spatial analysis.

For each incident and parcel, the nearest firehouse was identified using spatial indexing and nearest-neighbor search operations.

Distances were calculated using projected geometries in EPSG:2263 and converted from feet to miles.

Two analytical perspectives were produced:

1. **Incident-level proximity:** Distance from each spatially valid 311 incident to its nearest firehouse.
2. **Parcel-level proximity:** Distance from each NYC parcel to its nearest firehouse.

The results were subsequently summarized using descriptive statistics, including mean, median, percentile values, and distance-based counts.

These measurements represent straight-line geographic distances. They do not account for road networks, traffic conditions, firehouse deployment, vehicle availability, or emergency response times.

### 5.3 Parcel-Level Incident Profiles

Incident records associated with individual parcels were aggregated to develop parcel-level incident profiles.

The resulting dataset provides a summary of recorded 311 activity for each parcel, including incident counts, complaint-type diversity, and agency diversity.

These profiles support the identification of parcels with unusually high numbers of recorded service requests and allow comparisons across the city's parcel inventory.

Incident counts represent recorded 311 requests rather than independently verified incidents or direct measurements of property conditions.

### 5.4 Rite Aid Proximity Analysis

A nearest-neighbor analysis was conducted to measure the straight-line geographic distance between NYC parcels and the nearest recorded Rite Aid location.

Each parcel was associated with its nearest pharmacy, and the corresponding distance was calculated in miles.

For focused comparison, parcels with recorded 311 incidents were ranked by incident count. The highest-incident group was selected using the 95th-percentile incident-count threshold.

This analysis combines parcel-level incident profiles with the geographic distribution of the recorded Rite Aid locations.

The results describe spatial proximity to the selected pharmacy dataset only. They should not be interpreted as a comprehensive assessment of healthcare accessibility, pharmacy availability, service utilization, or community healthcare needs.

### 5.5 Integrated Hotspot and Firehouse Analysis

The hotspot grid and firehouse proximity results were integrated to examine the relationship between incident density and geographic proximity to FDNY firehouses.

Each occupied hotspot cell was associated with its nearest firehouse, and its density classification and nearest-firehouse distance were retained in the integrated analytical dataset.

The analysis examined:

- Incident distribution across hotspot density classes.
- Mean and median distance to the nearest firehouse.
- The proportion of hotspot cells within one mile of a firehouse.
- High-density hotspot cells located more than one mile from their nearest firehouse.

This integration allowed the identification of three high-density hotspot cells located more than one mile from their nearest firehouse.

The identified locations represent spatial exceptions within the observed distribution. They do not independently establish deficiencies in emergency response or fire-service coverage.

## 6. Statistical Assessment

Descriptive statistical methods were used to summarize the analytical results and compare spatial patterns.

The principal statistical measures included:

- Record and feature counts.
- Mean and median values.
- Percentile distributions.
- Minimum and maximum values.
- Distance-based proportions.
- Aggregated incident counts by density class.

Percentile-based classifications were used where appropriate to account for highly skewed distributions and to identify relatively high-value observations.

Statistical summaries were generated from the derived analytical datasets and used to support the final cartographic and tabular outputs.

## 7. Cartographic Visualization

QGIS was used to visualize the analytical outputs and prepare the final map layouts.

Different cartographic techniques were selected according to the analytical purpose of each output, including:

- Graduated symbology for incident counts and distance measurements.
- Categorized symbology for empirical hotspot density classes.
- Variable outline widths to represent secondary distance information.
- Distinct point symbols for firehouse and pharmacy locations.
- Comparative thematic maps to display different spatial variables without overloading a single map.

The final layouts include map titles, legends, explanatory notes, and relevant geographic reference information.

All thematic representations are designed to communicate the spatial patterns of the derived datasets without implying relationships or operational conclusions that the underlying data cannot establish.

## 8. Methodological Limitations

The findings should be interpreted within the limitations of the datasets and analytical methods.

1. **311 records:** Service requests represent reported issues and do not necessarily correspond to independently verified incidents. Reporting behavior and frequency may vary geographically.

2. **Spatial completeness:** Records without valid geometries were excluded from geometry-dependent analyses, which may affect the spatial representation of the complete 311 dataset.

3. **Parcel association:** Incident-to-parcel matching depends on the availability and accuracy of BBL identifiers and geographic coordinates. Spatial assignment of records without BBL identifiers introduces additional positional uncertainty.

4. **Grid-based analysis:** The selection of a 1,000 ft grid size influences the spatial aggregation of incident counts. Grid-based hotspot patterns should not be interpreted as exact parcel-level concentrations.

5. **Distance measurements:** Nearest-facility distances are straight-line measurements and do not represent actual travel distances, travel times, or operational accessibility.

6. **Pharmacy dataset coverage:** The Rite Aid dataset contains 100 recorded locations and does not represent every pharmacy operating in NYC. The resulting proximity measurements are specific to this dataset.

7. **Temporal scope:** The primary incident analysis covers 2021. The results describe the selected study period and should not automatically be interpreted as current spatial conditions.

8. **Interpretation of spatial relationships:** Geographic proximity and spatial concentration do not establish causation, service quality, infrastructure adequacy, or actual demand for public services.

## 9. Technical Environment

The project uses the following technologies:

| Technology | Application |
|---|---|
| PostgreSQL | Relational database management |
| PostGIS | Spatial data storage and spatial operations |
| SQL | Data preparation, quality control, aggregation, and spatial analysis |
| Python | Supporting data-processing and database workflows |
| QGIS | Spatial visualization and cartographic production |
| Docker | Database environment deployment and management |
| Git / GitHub | Version control and project documentation |

The analytical workflow is organized into sequential SQL processing stages to support reproducibility, maintainability, and clear separation between data preparation and analytical operations.