# Findings

## 1. Overview

This project examines the spatial distribution of NYC 311 service requests during 2021 and investigates their geographic relationships with NYC parcels, FDNY firehouses, and recorded Rite Aid locations.

The analysis combines more than 3.2 million 311 records with parcel-level property information and facility locations to identify spatial concentrations, examine nearest-facility distances, and investigate relationships between incident density and geographic proximity.

The principal findings are organized into five analytical areas:

1. NYC 311 incident distribution and hotspot concentration.
2. Incident association with NYC parcels.
3. Geographic proximity to FDNY firehouses.
4. Geographic proximity to recorded Rite Aid locations.
5. Integrated hotspot density and firehouse proximity analysis.

## 2. NYC 311 Incident Distribution and Hotspots

### 2.1 Spatial Coverage

The 2021 NYC 311 dataset contains 3,214,361 records.

Of these, 3,142,352 records had valid spatial geometries and were included in geometry-dependent analyses.

The remaining 72,009 records had missing or invalid geometries and were excluded from spatial operations.

A regular grid consisting of 1,000 ft × 1,000 ft cells was used to examine the geographic distribution of incidents. The analysis identified 7,620 occupied grid cells containing all 3,142,352 spatially valid incidents.

### 2.2 Incident Concentration

Incident counts across the occupied grid cells exhibited a highly skewed distribution.

| Statistic | Incident count per cell |
|---|---:|
| Minimum | 1 |
| Median | 232 |
| Mean | 412.38 |
| 90th percentile | 981.1 |
| 95th percentile | 1,342.1 |
| 99th percentile | 2,500.86 |
| Maximum | 42,000 |

The substantial difference between the median and maximum indicates that incident activity was not distributed evenly across the grid.

A relatively small proportion of cells contained considerably higher numbers of recorded incidents.

### 2.3 Empirical Hotspot Classification

To identify areas with relatively high incident concentrations, percentile-based thresholds were applied to the grid-cell incident counts.

| Classification | Threshold | Number of cells |
|---|---|---:|
| Extreme | 99th percentile and above | 77 |
| Very High | 95th percentile and above, below 99th | 304 |
| High | 90th percentile and above, below 95th | 381 |
| Other | Below 90th percentile | 6,858 |
| **Total** | | **7,620** |

The three high-density categories together contain 762 cells, representing the upper 10% of occupied grid cells.

These cells account for 1,272,440 recorded incidents, approximately 40.5% of all spatially valid 311 records.

This demonstrates a pronounced concentration of recorded service requests within a relatively small proportion of the occupied grid cells.

The classifications are empirical and dataset-specific. They do not represent official NYC hotspot designations.

## 3. Parcel-Level Incident Analysis

### 3.1 Incident-to-Parcel Association

The parcel-level analysis used 856,997 unique NYC parcels.

Incident records were associated with parcels primarily through BBL identifiers, supplemented by spatial assignment for eligible records without BBL identifiers.

The resulting association statistics were:

| Measure | Records |
|---|---:|
| Total 311 records | 3,214,361 |
| Records with a BBL identifier | 2,834,324 |
| Records without a BBL identifier | 380,037 |
| Records successfully matched to parcels | 2,820,963 |
| Records with unmatched BBL identifiers | 13,361 |

An additional 8,420 spatially valid incidents without BBL identifiers were assigned to 1,234 parcels through spatial analysis.

Overall, 2,820,963 incidents were associated with parcels, representing approximately 87.75% of the complete 311 dataset.

### 3.2 Distribution of Parcel-Level Incidents

The parcel incident profiles produced the following results:

| Measure | Result |
|---|---:|
| Total parcels | 856,997 |
| Parcels with recorded incidents | 453,193 |
| Parcels without linked incidents | 403,804 |
| Total linked incidents | 2,820,963 |
| Mean incidents per parcel | 3.29 |
| Median incidents per parcel | 1 |
| Maximum incidents associated with one parcel | 30,589 |

Approximately 52.9% of parcels had at least one associated 311 incident.

The difference between the mean and median indicates a highly uneven distribution of recorded incidents among parcels.

One parcel, located at 672 East 231 Street in the Bronx, was associated with 30,589 incidents. Approximately 99.97% of its recorded incidents were classified as Noise - Residential.

This exceptional concentration should be interpreted as a concentration of recorded service requests associated with one parcel, rather than direct evidence of property condition or an independently verified level of risk.

## 4. FDNY Firehouse Proximity Analysis

### 4.1 Firehouse Dataset

The analysis incorporated 219 FDNY firehouse locations.

Nearest-neighbor analysis was used to calculate the straight-line geographic distance from incidents and parcels to their nearest firehouse.

### 4.2 Incident-Level Proximity

The distance analysis covered all 3,142,352 spatially valid 311 incidents.

| Statistic | Distance |
|---|---:|
| Mean | 0.405 miles |
| Median | 0.356 miles |
| 90th percentile | 0.722 miles |
| 95th percentile | 0.870 miles |
| Maximum | 2.655 miles |

Approximately 97.38% of spatially valid incidents were located within one mile of their nearest firehouse.

These results describe the geographic proximity of recorded incident locations to FDNY firehouses.

### 4.3 Parcel-Level Proximity

The parcel-level analysis evaluated the distance from each of the 856,997 NYC parcels to its nearest firehouse.

| Statistic | Distance |
|---|---:|
| Mean | 0.513 miles |
| Median | 0.464 miles |
| Parcels within 0.5 miles | 55.08% |

The parcel-level results provide a broader view of the geographic distribution of firehouse proximity across the city's parcel inventory.

The difference between incident-level and parcel-level measurements reflects the different spatial distributions and analytical units used in these two analyses.

## 5. Rite Aid Proximity Analysis

### 5.1 Geographic Distribution

The pharmacy dataset contains 100 recorded Rite Aid locations.

Their distribution across the five boroughs is uneven:

| Borough | Recorded Rite Aid locations |
|---|---:|
| Brooklyn | 70 |
| Queens | 30 |
| Bronx | 0 |
| Manhattan | 0 |
| Staten Island | 0 |
| **Total** | **100** |

All 100 pharmacy records were successfully associated with matching MapPLUTO parcel identifiers and geometries.

The dataset therefore represents a specific subset of recorded pharmacy locations rather than a comprehensive inventory of NYC pharmacies.

### 5.2 Parcel-to-Pharmacy Distance

The distance between each parcel and its nearest recorded Rite Aid location was calculated using straight-line geographic measurements.

| Statistic | Distance |
|---|---:|
| Mean | 3.375 miles |
| Median | 2.643 miles |
| 90th percentile | 7.517 miles |
| 95th percentile | 9.360 miles |
| Maximum | 15.167 miles |

The borough-level mean distances were:

| Borough | Mean distance to nearest Rite Aid |
|---|---:|
| Brooklyn | 0.962 miles |
| Manhattan | 3.089 miles |
| Queens | 2.987 miles |
| Bronx | 6.767 miles |
| Staten Island | 7.384 miles |

The results reflect the geographic distribution of the 100 recorded Rite Aid locations and their proximity to NYC parcels.

The relatively large distances observed in some boroughs are consistent with the absence of recorded Rite Aid locations in those boroughs.

These findings should not be interpreted as a comprehensive measure of pharmacy accessibility or healthcare availability. Other pharmacy providers and factors affecting actual access were outside the scope of this analysis.

## 6. Integrated Hotspot Density and Firehouse Proximity

### 6.1 Relationship Between Hotspot Density and Firehouse Distance

The hotspot grid was integrated with nearest-firehouse information to investigate how geographic proximity varied across incident density classifications.

The analysis produced the following results:

| Density class | Hotspot cells | Recorded incidents | Mean distance to nearest firehouse |
|---|---:|---:|---:|
| Extreme | 77 | 307,172 | 0.298 miles |
| Very High | 304 | 530,654 | 0.321 miles |
| High | 381 | 434,614 | 0.328 miles |
| Other | 6,858 | 1,869,912 | 0.611 miles |
| **Total** | **7,620** | **3,142,352** | — |

The results reveal a clear descriptive pattern: the three high-density hotspot categories have lower mean distances to their nearest firehouses than the remaining grid cells.

The Extreme category has the lowest mean distance, at 0.298 miles, compared with 0.611 miles for the Other category.

This indicates that, within the analyzed dataset, the most concentrated areas of recorded 311 activity tend to be geographically closer to FDNY firehouses.

### 6.2 High-Density Hotspots Within One Mile of Firehouses

The 762 cells classified as High, Very High, or Extreme were examined separately.

| Measure | Result |
|---|---:|
| Total high-density cells | 762 |
| Within 0.5 miles | 660 (86.6%) |
| Within 1 mile | 759 (99.6%) |
| More than 1 mile away | 3 (0.4%) |
| More than 2 miles away | 0 |

The results show that nearly all high-density hotspot cells were located within one mile of their nearest firehouse.

Only three high-density cells were located more than one mile away.

### 6.3 Distant High-Density Hotspots

The three identified cells were examined as individual spatial exceptions.

| Measure | Result |
|---|---:|
| Number of cells | 3 |
| Mean distance to nearest firehouse | 1.239 miles |
| Maximum distance | 1.651 miles |

These cells represent the relatively small number of high-density hotspot locations that fall outside the one-mile distance threshold.

Their identification provides a focused view of locations where high recorded incident concentrations coincide with greater geographic distance from the nearest firehouse.

However, these locations cannot independently be classified as underserved or as areas with inadequate emergency response. Such conclusions would require additional information, including road-network travel times, deployment patterns, firehouse capacity, and operational response data.

## 7. Key Findings

The combined analyses support the following principal findings:

1. **Uneven incident distribution:** NYC 311 service requests were spatially concentrated. The upper 10% of occupied grid cells accounted for approximately 40.5% of spatially valid incidents.

2. **Uneven parcel-level distribution:** Approximately 52.9% of NYC parcels had at least one associated 311 record, while the parcel incident-count distribution was strongly skewed.

3. **Geographic proximity to firehouses:** Approximately 97.38% of spatially valid 311 incidents were located within one mile of their nearest FDNY firehouse.

4. **Density and proximity relationship:** High-density hotspot cells had substantially lower mean distances to their nearest firehouses than the remaining grid cells.

5. **Limited number of distant high-density hotspots:** Only three of the 762 high-density hotspot cells were located more than one mile from their nearest firehouse.

6. **Uneven Rite Aid distribution:** All 100 recorded Rite Aid locations were concentrated in Brooklyn and Queens, producing substantial differences in parcel-to-Rite Aid distances across boroughs.

## 8. Interpretation and Limitations

The findings describe spatial patterns and geographic relationships within the selected datasets and study period.

Several distinctions are important when interpreting the results:

- A 311 service request represents a reported issue, not necessarily an independently verified incident.
- A high incident count indicates a concentration of recorded service requests, not necessarily a direct measure of property condition, population-level risk, or service demand.
- Straight-line distance to a firehouse does not represent actual emergency response time or operational coverage.
- Proximity to recorded Rite Aid locations does not establish healthcare accessibility or pharmacy availability.
- The Rite Aid analysis is limited to the 100 locations included in the source dataset.
- The results describe 2021 incident patterns and should not automatically be interpreted as current conditions.

The project therefore focuses on spatial description, measurement, and comparison rather than causal inference or operational performance evaluation.

## 9. Conclusion

The project demonstrates how spatial databases, SQL-based analysis, and GIS visualization can be integrated to investigate urban service-request patterns and their geographic relationships with selected facilities.

The combined use of parcel-level aggregation, grid-based hotspot analysis, nearest-neighbor distance calculations, and integrated spatial summaries provides multiple perspectives on the distribution of recorded 311 activity across New York City.

The results highlight substantial spatial variation in recorded incidents, reveal a descriptive relationship between hotspot density and firehouse proximity, and demonstrate the uneven geographic distribution of the selected Rite Aid locations.

Together, these analyses provide a reproducible spatial analytical workflow and a foundation for more detailed investigations involving population data, transportation networks, facility capacity, and operational service measurements.