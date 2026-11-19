# Data Dictionary

## 1. Overview

This document describes the principal datasets, database tables, attributes, and spatial fields used in the **NYC Urban Services, Incidents & Spatial Analysis** project.

The PostgreSQL/PostGIS database is organized into three primary schemas:

| Schema | Purpose |
|---|---|
| `raw` | Original imported source datasets. |
| `core` | Cleaned, standardized, and spatially prepared datasets. |
| `analysis` | Derived datasets, spatial analysis results, and statistical summaries. |

The data dictionary documents the actual database structures, including field names and PostgreSQL data types.

Unless otherwise specified, spatial geometries use **EPSG:2263 (NAD83 / New York Long Island)**.

Distance measurements are expressed in feet or miles, as indicated by the corresponding field names.

---

## 2. Core Schema

The `core` schema contains the principal prepared datasets used throughout the analytical workflow.

### 2.1 `core.incidents`

**Description:** Cleaned NYC 311 service-request records for calendar year 2021.

**Records:** 3,214,361

**Spatial records:** 3,142,352 valid geometries.

**Geometry:** Point (`geom`), with an additional geographic geometry (`geom_4326`).

| Field | PostgreSQL type | Description |
|---|---|---|
| `incident_id` | bigint | Unique identifier for the incident, derived from the source record identifier. |
| `created_at` | timestamptz | Date and time when the service request was created. |
| `closed_at` | timestamptz | Date and time when the service request was closed. |
| `agency` | text | Abbreviation of the responsible agency. |
| `agency_name` | text | Full name of the responsible agency. |
| `complaint_type` | text | General category of the reported complaint. |
| `descriptor` | text | Additional description of the complaint. |
| `location_type` | text | Type of location associated with the service request. |
| `incident_zip` | text | ZIP code associated with the incident. |
| `incident_address` | text | Street address associated with the incident. |
| `street_name` | text | Street name associated with the incident. |
| `cross_street_1` | text | First cross street. |
| `cross_street_2` | text | Second cross street. |
| `intersection_street_1` | text | First intersection street. |
| `intersection_street_2` | text | Second intersection street. |
| `address_type` | text | Type of address information supplied. |
| `city` | text | City associated with the incident. |
| `landmark` | text | Associated landmark, when available. |
| `facility_type` | text | Type of facility associated with the request. |
| `status` | text | Current or final status of the request. |
| `due_at` | timestamptz | Expected resolution deadline. |
| `resolution_description` | text | Description of the resolution. |
| `resolution_action_updated_at` | timestamptz | Timestamp of the latest resolution-action update. |
| `community_board` | text | NYC community board identifier. |
| `bbl` | double precision | Borough-Block-Lot identifier associated with the incident. |
| `borough` | text | NYC borough associated with the incident. |
| `x_coordinate_state_plane` | double precision | State Plane X coordinate from the source dataset. |
| `y_coordinate_state_plane` | double precision | State Plane Y coordinate from the source dataset. |
| `open_data_channel_type` | text | Channel through which the service request was submitted. |
| `park_facility_name` | text | Associated park or facility name. |
| `park_borough` | text | Borough associated with the park facility. |
| `vehicle_type` | text | Vehicle type, when applicable. |
| `taxi_company_borough` | text | Borough associated with the taxi company. |
| `taxi_pick_up_location` | text | Taxi pickup location information. |
| `bridge_highway_name` | text | Associated bridge or highway name. |
| `bridge_highway_direction` | text | Bridge or highway direction. |
| `road_ramp` | text | Road ramp information. |
| `bridge_highway_segment` | text | Associated bridge or highway segment. |
| `latitude` | double precision | Geographic latitude. |
| `longitude` | double precision | Geographic longitude. |
| `geom_4326` | geometry | Geographic point geometry in the original geographic coordinate system. |
| `geom` | geometry | Projected point geometry used in spatial analysis. |

**Data quality notes:**

- The dataset contains 72,009 records without usable spatial geometries.
- 72,008 records have missing latitude or longitude values.
- One record contains an invalid location near coordinates (0, 0).
- Records without valid geometries are retained in the dataset but excluded from geometry-dependent analyses.
- The original incident identifier is retained to support record-level traceability.

### 2.2 `core.parcels`

**Description:** NYC tax parcel dataset derived from MapPLUTO and prepared for spatial integration.

**Records:** 856,997

**Geometry:** Polygon/MultiPolygon (`geom`).

| Field | PostgreSQL type | Description |
|---|---|---|
| `bbl` | bigint | Unique Borough-Block-Lot parcel identifier. |
| `borough` | text | Borough in which the parcel is located. |
| `block` | integer | Tax block identifier. |
| `lot` | integer | Tax lot identifier. |
| `zipcode` | integer | ZIP code associated with the parcel. |
| `address` | text | Parcel street address. |
| `zoning` | text | Zoning classification. |
| `land_use` | text | General land-use classification. |
| `building_class` | text | Building classification code. |
| `lot_area` | double precision | Total parcel area. |
| `building_area` | double precision | Total building floor area. |
| `commercial_area` | double precision | Commercial floor area. |
| `residential_area` | double precision | Residential floor area. |
| `office_area` | double precision | Office floor area. |
| `retail_area` | double precision | Retail floor area. |
| `garage_area` | double precision | Garage floor area. |
| `storage_area` | double precision | Storage floor area. |
| `factory_area` | double precision | Factory floor area. |
| `other_area` | double precision | Other recorded building floor area. |
| `num_buildings` | integer | Number of buildings on the parcel. |
| `num_floors` | double precision | Number of floors recorded for the parcel. |
| `units_res` | integer | Number of residential units. |
| `units_total` | integer | Total number of units. |
| `lot_front` | double precision | Parcel frontage measurement. |
| `lot_depth` | double precision | Parcel depth measurement. |
| `building_front` | double precision | Building frontage measurement. |
| `building_depth` | double precision | Building depth measurement. |
| `year_built` | integer | Recorded construction year. |
| `assess_land` | double precision | Assessed land value. |
| `assess_total` | double precision | Total assessed property value. |
| `x_coord` | double precision | Projected X coordinate. |
| `y_coord` | double precision | Projected Y coordinate. |
| `latitude` | double precision | Geographic latitude. |
| `longitude` | double precision | Geographic longitude. |
| `geom` | geometry | Parcel polygon geometry. |

**Data quality notes:**

- BBL is the primary parcel identifier used for incident association.
- Missing construction-year values are represented as NULL rather than zero.
- Building area represents total floor area and may exceed the parcel's land area.

### 2.3 `core.firehouses`

**Description:** FDNY firehouse locations used for nearest-facility and proximity analysis.

**Records:** 219

**Geometry:** Point (`geom`).

| Field | PostgreSQL type | Description |
|---|---|---|
| `firehouse_id` | integer | Firehouse identifier. |
| `facility_name` | text | Firehouse name. |
| `address` | text | Firehouse street address. |
| `borough` | text | Borough in which the firehouse is located. |
| `postcode` | integer | Postal code. |
| `community_board` | integer | Associated NYC community board. |
| `community_council` | integer | Associated community council district. |
| `census_tract` | integer | Census tract identifier. |
| `bin` | bigint | Building Identification Number. |
| `bbl` | bigint | Associated Borough-Block-Lot identifier. |
| `nta` | text | Neighborhood Tabulation Area identifier. |
| `latitude` | double precision | Geographic latitude. |
| `longitude` | double precision | Geographic longitude. |
| `geom` | geometry | Projected firehouse point geometry. |

**Analytical role:**

This dataset provides the reference locations used to calculate nearest-firehouse distances for 311 incidents, hotspot grid cells, and NYC parcels.

### 2.4 `core.pharmacies`

**Description:** Recorded Rite Aid pharmacy locations used in the pharmacy proximity analysis.

**Records:** 100

**Geometry:** Point (`geom`), with an additional geographic geometry (`geom_4326`).

| Field | PostgreSQL type | Description |
|---|---|---|
| `pharmacy_id` | bigint | Pharmacy record identifier. |
| `bbl` | bigint | Associated parcel BBL identifier. |
| `pharm_id` | text | Pharmacy identifier retained from the source dataset. |
| `name` | text | Pharmacy name. |
| `geom_4326` | geometry | Geographic point geometry. |
| `geom` | geometry | Projected point geometry. |

**Geographic distribution:**

| Borough | Locations |
|---|---:|
| Brooklyn | 70 |
| Queens | 30 |
| Bronx | 0 |
| Manhattan | 0 |
| Staten Island | 0 |
| **Total** | **100** |

**Data quality notes:**

All 100 pharmacy records were successfully associated with matching MapPLUTO parcel identifiers and geometries.

This dataset represents the selected Rite Aid locations rather than a comprehensive inventory of pharmacies operating in NYC.

### 2.5 `core.weather_stations`

**Description:** Weather station observations retained in the core database.

| Field | PostgreSQL type | Description |
|---|---|---|
| `weather_id` | bigint | Weather observation record identifier. |
| `station` | text | Weather station identifier or name. |
| `observed_at` | timestamptz | Observation timestamp. |
| `latitude` | double precision | Geographic latitude. |
| `longitude` | double precision | Geographic longitude. |
| `elevation_m` | double precision | Station elevation in meters. |
| `temp_2m_max_c` | double precision | Maximum temperature at 2 meters, in Celsius. |
| `temp_2m_min_c` | double precision | Minimum temperature at 2 meters, in Celsius. |
| `temp_2m_avg_c` | double precision | Average temperature at 2 meters, in Celsius. |
| `apparent_temperature_max_c` | double precision | Maximum apparent temperature, in Celsius. |
| `apparent_temperature_min_c` | double precision | Minimum apparent temperature, in Celsius. |
| `apparent_temperature_avg_c` | double precision | Average apparent temperature, in Celsius. |
| `geom_4326` | geometry | Geographic station point geometry. |
| `geom` | geometry | Projected station point geometry. |

**Analytical role:**

Weather station observations are retained as supporting environmental data. They are not part of the principal 311 incident, parcel, or facility-proximity analyses documented in the final outputs.

---

## 3. Analysis Schema

The `analysis` schema contains the derived spatial datasets, aggregated profiles, and analytical outputs.

### 3.1 `analysis.incident_hotspots`

**Description:** Regular-grid aggregation of spatially valid NYC 311 incidents.

**Records:** 7,620 occupied grid cells.

**Grid dimensions:** 1,000 ft × 1,000 ft.

| Field | PostgreSQL type | Description |
|---|---|---|
| `hotspot_id` | bigint | Unique identifier for the grid cell. |
| `incident_count` | bigint | Number of incident records assigned to the grid cell. |
| `unique_incident_count` | bigint | Number of unique incidents represented in the cell. |
| `geom` | geometry | Grid-cell polygon geometry. |

**Important:** Density classification and firehouse proximity attributes are stored in `analysis.integrated_hotspot_profiles`, not in this table.

### 3.2 `analysis.integrated_hotspot_profiles`

**Description:** Integrated hotspot dataset combining incident concentration, density classification, and nearest-firehouse proximity.

**Records:** 7,620.

| Field | PostgreSQL type | Description |
|---|---|---|
| `hotspot_id` | bigint | Unique identifier of the hotspot grid cell. |
| `incident_count` | bigint | Number of incidents assigned to the cell. |
| `unique_incident_count` | bigint | Number of unique incidents represented in the cell. |
| `geom` | geometry | Grid-cell polygon geometry. |
| `density_class` | text | Empirical incident-density classification. |
| `annual_incidents_per_square_mile` | numeric | Annual incident-count equivalent per square mile. |
| `firehouse_id` | integer | Identifier of the nearest firehouse. |
| `facility_name` | text | Name of the nearest firehouse. |
| `firehouse_address` | text | Address of the nearest firehouse. |
| `firehouse_borough` | text | Borough of the nearest firehouse. |
| `distance_ft` | double precision | Straight-line distance to the nearest firehouse, in feet. |
| `distance_miles` | numeric | Straight-line distance to the nearest firehouse, in miles. |

**Density classification:**

| Class | Threshold |
|---|---|
| Other | Below the 90th percentile |
| High | 90th percentile to below the 95th percentile |
| Very High | 95th percentile to below the 99th percentile |
| Extreme | 99th percentile and above |

### 3.3 `analysis.distant_high_density_hotspots`

**Description:** High-density hotspot cells located more than one mile from their nearest FDNY firehouse.

**Records:** 3.

| Field | PostgreSQL type | Description |
|---|---|---|
| `hotspot_id` | bigint | Unique hotspot grid-cell identifier. |
| `incident_count` | bigint | Total incident count. |
| `unique_incident_count` | bigint | Number of unique incidents. |
| `geom` | geometry | Grid-cell polygon geometry. |
| `density_class` | text | Hotspot density classification. |
| `annual_incidents_per_square_mile` | numeric | Annual incident-count equivalent per square mile. |
| `firehouse_id` | integer | Nearest firehouse identifier. |
| `facility_name` | text | Nearest firehouse name. |
| `firehouse_address` | text | Nearest firehouse address. |
| `firehouse_borough` | text | Borough of the nearest firehouse. |
| `distance_ft` | double precision | Distance to the nearest firehouse, in feet. |
| `distance_miles` | numeric | Distance to the nearest firehouse, in miles. |

**Analytical role:**

This table isolates the three high-density hotspot cells located more than one mile from their nearest firehouse.

### 3.4 `analysis.incident_clusters`

**Description:** Incident-level spatial cluster assignments.

| Field | PostgreSQL type | Description |
|---|---|---|
| `incident_id` | bigint | Unique incident identifier. |
| `borough` | text | Incident borough. |
| `complaint_type` | text | Complaint category. |
| `created_at` | timestamptz | Incident creation timestamp. |
| `cluster_id` | integer | Assigned spatial cluster identifier. |
| `geom` | geometry | Incident point geometry. |

### 3.5 `analysis.incident_cluster_summary`

**Description:** Aggregated statistical summary of identified incident clusters.

| Field | PostgreSQL type | Description |
|---|---|---|
| `cluster_id` | integer | Spatial cluster identifier. |
| `incident_count` | bigint | Number of incidents in the cluster. |
| `complaint_type_count` | bigint | Number of distinct complaint types represented. |
| `borough_count` | bigint | Number of boroughs represented. |
| `first_incident` | timestamptz | Earliest incident timestamp in the cluster. |
| `last_incident` | timestamptz | Latest incident timestamp in the cluster. |
| `geom` | geometry | Cluster geometry. |

### 3.6 `analysis.incident_hotspots_borough`

**Description:** Borough-level aggregation of hotspot incident information.

| Field | PostgreSQL type | Description |
|---|---|---|
| `borough` | text | Borough name. |
| `incident_count` | bigint | Aggregated incident count. |
| `complaint_type_count` | bigint | Number of distinct complaint types. |
| `active_months` | bigint | Number of months with recorded activity. |

### 3.7 `analysis.incident_parcel_spatial_assignment`

**Description:** Records of incidents associated with parcels through spatial assignment.

| Field | PostgreSQL type | Description |
|---|---|---|
| `incident_id` | bigint | Incident identifier. |
| `bbl` | bigint | Assigned parcel identifier. |
| `created_at` | timestamptz | Incident creation timestamp. |
| `complaint_type` | text | Complaint category. |
| `agency` | text | Responsible agency. |
| `incident_borough` | text | Borough associated with the incident. |
| `land_use` | text | Land-use classification of the associated parcel. |
| `building_class` | text | Building classification of the associated parcel. |
| `parcel_geom` | geometry | Associated parcel geometry. |

### 3.8 `analysis.incident_firehouse_accessibility`

**Description:** Incident-level dataset containing nearest-firehouse information and geographic distances.

| Field | PostgreSQL type | Description |
|---|---|---|
| `incident_id` | bigint | Incident identifier. |
| `created_at` | timestamptz | Incident creation timestamp. |
| `complaint_type` | text | Complaint category. |
| `agency` | text | Responsible agency. |
| `borough` | text | Incident borough. |
| `geom` | geometry | Incident point geometry. |
| `firehouse_id` | integer | Nearest firehouse identifier. |
| `facility_name` | text | Nearest firehouse name. |
| `firehouse_borough` | text | Borough of the nearest firehouse. |
| `address` | text | Nearest firehouse address. |
| `distance_ft` | double precision | Distance to the nearest firehouse, in feet. |
| `distance_miles` | numeric | Distance to the nearest firehouse, in miles. |

### 3.9 `analysis.incident_firehouse_accessibility_classes`

**Description:** Incident-level firehouse accessibility dataset with an additional categorical distance classification.

This table contains the same fields as `analysis.incident_firehouse_accessibility`, with the following additional field:

| Field | PostgreSQL type | Description |
|---|---|---|
| `accessibility_class` | text | Categorical classification of incident-to-firehouse distance. |

### 3.10 `analysis.firehouse_incident_profiles`

**Description:** Aggregated incident proximity statistics for individual firehouses.

| Field | PostgreSQL type | Description |
|---|---|---|
| `firehouse_id` | integer | Firehouse identifier. |
| `facility_name` | text | Firehouse name. |
| `address` | text | Firehouse address. |
| `borough` | text | Firehouse borough. |
| `nearest_incident_count` | bigint | Number of incidents associated with the firehouse through nearest-firehouse assignment. |
| `mean_incident_distance_miles` | numeric | Mean distance of associated incidents, in miles. |
| `median_incident_distance_miles` | numeric | Median incident distance, in miles. |
| `p90_incident_distance_miles` | numeric | 90th-percentile incident distance, in miles. |
| `max_incident_distance_miles` | numeric | Maximum incident distance, in miles. |

### 3.11 `analysis.firehouse_hotspot_profiles`

**Description:** Aggregated hotspot statistics grouped by nearest firehouse.

| Field | PostgreSQL type | Description |
|---|---|---|
| `firehouse_id` | integer | Firehouse identifier. |
| `facility_name` | text | Firehouse name. |
| `firehouse_address` | text | Firehouse address. |
| `firehouse_borough` | text | Firehouse borough. |
| `hotspot_cells` | bigint | Number of associated hotspot cells. |
| `incidents_in_hotspot_cells` | numeric | Total incidents represented in associated hotspot cells. |
| `mean_hotspot_distance_miles` | numeric | Mean distance of associated hotspot cells to the firehouse, in miles. |
| `max_hotspot_distance_miles` | numeric | Maximum distance of associated hotspot cells, in miles. |
| `extreme_hotspot_cells` | bigint | Number of associated Extreme-density cells. |
| `very_high_hotspot_cells` | bigint | Number of associated Very High-density cells. |
| `high_hotspot_cells` | bigint | Number of associated High-density cells. |

### 3.12 `analysis.firehouse_distance_buffers`

**Description:** Precomputed distance buffer geometries around individual FDNY firehouses.

| Field | PostgreSQL type | Description |
|---|---|---|
| `firehouse_id` | integer | Firehouse identifier. |
| `facility_name` | text | Firehouse name. |
| `borough` | text | Firehouse borough. |
| `firehouse_geom` | geometry | Firehouse point geometry. |
| `buffer_0_5_miles` | geometry | Buffer polygon representing a 0.5-mile radius. |
| `buffer_1_mile` | geometry | Buffer polygon representing a 1-mile radius. |
| `buffer_2_miles` | geometry | Buffer polygon representing a 2-mile radius. |

### 3.13 `analysis.firehouse_accessibility_borough`

**Description:** Borough-level summary of incident proximity to FDNY firehouses.

| Field | PostgreSQL type | Description |
|---|---|---|
| `borough` | text | Borough name. |
| `incident_count` | bigint | Number of incidents included in the borough summary. |
| `mean_distance_miles` | numeric | Mean distance to the nearest firehouse, in miles. |
| `median_distance_miles` | numeric | Median distance to the nearest firehouse, in miles. |
| `p90_distance_miles` | numeric | 90th-percentile distance, in miles. |
| `incidents_within_0_5_miles` | bigint | Number of incidents within 0.5 miles of a firehouse. |
| `percent_within_0_5_miles` | numeric | Percentage of incidents within 0.5 miles. |
| `incidents_beyond_2_miles` | bigint | Number of incidents beyond 2 miles. |
| `percent_beyond_2_miles` | numeric | Percentage of incidents beyond 2 miles. |

### 3.14 `analysis.parcel_incident_profiles`

**Description:** Parcel-level aggregation of NYC 311 incidents and selected MapPLUTO attributes.

**Records:** 856,997.

| Field | PostgreSQL type | Description |
|---|---|---|
| `bbl` | bigint | Unique parcel identifier. |
| `borough` | text | Parcel borough. |
| `block` | integer | Tax block identifier. |
| `lot` | integer | Tax lot identifier. |
| `address` | text | Parcel address. |
| `land_use` | text | General land-use classification. |
| `building_class` | text | Building classification code. |
| `lot_area` | double precision | Parcel land area. |
| `building_area` | double precision | Total building floor area. |
| `residential_area` | double precision | Residential floor area. |
| `commercial_area` | double precision | Commercial floor area. |
| `office_area` | double precision | Office floor area. |
| `retail_area` | double precision | Retail floor area. |
| `num_buildings` | integer | Number of buildings. |
| `num_floors` | double precision | Number of floors. |
| `units_res` | integer | Number of residential units. |
| `units_total` | integer | Total number of units. |
| `year_built` | integer | Construction year. |
| `incident_count` | bigint | Number of associated 311 incidents. |
| `complaint_type_count` | bigint | Number of distinct complaint types. |
| `agency_count` | bigint | Number of distinct agencies. |
| `first_incident_at` | timestamptz | Earliest associated incident timestamp. |
| `last_incident_at` | timestamptz | Latest associated incident timestamp. |
| `geom` | geometry | Parcel polygon geometry. |

### 3.15 `analysis.parcel_pharmacy_accessibility`

**Description:** Parcel-level dataset combining incident counts and nearest recorded Rite Aid proximity.

| Field | PostgreSQL type | Description |
|---|---|---|
| `bbl` | bigint | Parcel identifier. |
| `borough` | text | Parcel borough. |
| `address` | text | Parcel address. |
| `land_use` | text | Land-use classification. |
| `building_class` | text | Building classification code. |
| `incident_count` | bigint | Number of associated 311 incidents. |
| `pharmacy_id` | bigint | Pharmacy record identifier. |
| `pharm_id` | text | Source pharmacy identifier. |
| `pharmacy_name` | text | Name of the associated nearest pharmacy. |
| `nearest_pharmacy_distance_miles` | double precision | Straight-line distance to the nearest recorded Rite Aid location, in miles. |
| `parcel_geom` | geometry | Parcel polygon geometry. |

### 3.16 `analysis.parcel_firehouse_accessibility`

**Description:** Parcel-level dataset containing nearest-firehouse information and geographic distance measurements.

**Records:** 856,997.

| Field | PostgreSQL type | Description |
|---|---|---|
| `bbl` | bigint | Parcel identifier. |
| `borough` | text | Parcel borough. |
| `address` | text | Parcel address. |
| `land_use` | text | Land-use classification. |
| `building_class` | text | Building classification code. |
| `lot_area` | double precision | Parcel land area. |
| `building_area` | double precision | Building floor area. |
| `units_res` | integer | Residential unit count. |
| `units_total` | integer | Total unit count. |
| `geom` | geometry | Parcel polygon geometry. |
| `firehouse_id` | integer | Nearest firehouse identifier. |
| `facility_name` | text | Nearest firehouse name. |
| `firehouse_borough` | text | Borough of the nearest firehouse. |
| `distance_ft` | double precision | Straight-line distance to the nearest firehouse, in feet. |
| `distance_miles` | numeric | Straight-line distance to the nearest firehouse, in miles. |

---

## 4. Identifiers and Measurement Conventions

### 4.1 BBL

BBL stands for Borough-Block-Lot.

It is the primary parcel identifier used to associate NYC 311 incidents and other spatial records with MapPLUTO tax parcels.

The identifier consists of three components:

- Borough code.
- Tax block number.
- Tax lot number.

### 4.2 Coordinate Reference System

The principal projected spatial datasets use:

**EPSG:2263 — NAD83 / New York Long Island (US survey feet).**

Geographic geometries are also retained in EPSG:4326 where applicable.

### 4.3 Distance Units

| Unit | Description |
|---|---|
| Feet (`ft`) | Linear measurement in the projected coordinate system. |
| Miles | Distance converted from feet using 5,280 feet per mile. |

Nearest-facility distances represent straight-line geographic measurements, not road-network distances or travel times.

### 4.4 Incident Density

The hotspot grid uses cells measuring 1,000 ft × 1,000 ft.

The annual incident-count equivalent per square mile is calculated as:

`incident_count × 27.8784`

The density classes use empirical percentile thresholds:

- Other: Below the 90th percentile.
- High: 90th percentile to below the 95th percentile.
- Very High: 95th percentile to below the 99th percentile.
- Extreme: 99th percentile and above.

These classifications are project-specific and are not official municipal standards.

---

## 5. Data Interpretation and Limitations

The datasets support the spatial analysis of recorded 311 service requests, property characteristics, and geographic proximity to selected facilities.

The following distinctions should be considered when interpreting the data:

- 311 records represent submitted service requests and do not necessarily correspond to independently verified incidents.
- Incident counts are not direct measurements of property condition, population-level risk, or service demand.
- Parcel association depends on the availability and accuracy of BBL identifiers and geographic locations.
- Hotspot classifications depend on the selected grid dimensions and percentile thresholds.
- Nearest-firehouse distances do not represent emergency response times or operational fire-service coverage.
- The Rite Aid dataset contains only 100 recorded locations and does not represent the complete NYC pharmacy market.
- Spatial proximity does not establish causation or service accessibility.

For additional methodological details, refer to [`methodology.md`](methodology.md).

For the principal analytical results and their interpretation, refer to [`findings.md`](findings.md).