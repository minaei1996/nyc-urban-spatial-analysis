-- ============================================================
-- 04_property_analysis.sql
-- NYC Urban Services, Incidents & Spatial Analysis
--
-- Purpose:
-- Analyze the relationship between NYC 311 incidents and
-- MapPLUTO parcel characteristics.
--
-- Main relationship:
--   core.incidents.bbl -> core.parcels.bbl
--
-- BBL is used as the primary relationship because it is an
-- explicit property identifier in the NYC 311 source data.
--
-- Spatial parcel assignment is handled separately as a
-- complementary analysis for incidents without a usable BBL.
-- ============================================================


-- ============================================================
-- 1. PROPERTY INCIDENT PROFILES
-- ============================================================

DROP TABLE IF EXISTS analysis.parcel_incident_profiles;

CREATE TABLE analysis.parcel_incident_profiles AS
SELECT
    p.bbl,
    p.borough,
    p.block,
    p.lot,
    p.address,
    p.land_use,
    p.building_class,

    p.lot_area,
    p.building_area,
    p.residential_area,
    p.commercial_area,
    p.office_area,
    p.retail_area,

    p.num_buildings,
    p.num_floors,
    p.units_res,
    p.units_total,
    p.year_built,

    COUNT(i.incident_id) AS incident_count,
    COUNT(DISTINCT i.complaint_type) AS complaint_type_count,
    COUNT(DISTINCT i.agency) AS agency_count,

    MIN(i.created_at) AS first_incident_at,
    MAX(i.created_at) AS last_incident_at,

    p.geom

FROM core.parcels p
LEFT JOIN core.incidents i
    ON i.bbl IS NOT NULL
   AND i.bbl::BIGINT = p.bbl

GROUP BY
    p.bbl,
    p.borough,
    p.block,
    p.lot,
    p.address,
    p.land_use,
    p.building_class,
    p.lot_area,
    p.building_area,
    p.residential_area,
    p.commercial_area,
    p.office_area,
    p.retail_area,
    p.num_buildings,
    p.num_floors,
    p.units_res,
    p.units_total,
    p.year_built,
    p.geom;


CREATE INDEX idx_parcel_incident_profiles_geom
    ON analysis.parcel_incident_profiles
    USING GIST (geom);

CREATE INDEX idx_parcel_incident_profiles_bbl
    ON analysis.parcel_incident_profiles (bbl);

CREATE INDEX idx_parcel_incident_profiles_incident_count
    ON analysis.parcel_incident_profiles (incident_count);


-- ============================================================
-- 2. PROPERTY INCIDENT SUMMARY
-- ============================================================

SELECT
    COUNT(*) AS parcel_count,

    COUNT(*) FILTER (
        WHERE incident_count > 0
    ) AS parcels_with_incidents,

    COUNT(*) FILTER (
        WHERE incident_count = 0
    ) AS parcels_without_incidents,

    SUM(incident_count) AS linked_incidents,

    ROUND(
        AVG(incident_count),
        2
    ) AS mean_incidents_per_parcel,

    PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY incident_count
        ) AS median_incidents_per_parcel,

    MAX(incident_count) AS max_incidents_per_parcel

FROM analysis.parcel_incident_profiles;


-- ============================================================
-- 3. BBL LINKAGE COVERAGE
-- ============================================================

SELECT
    COUNT(*) AS total_incidents,

    COUNT(*) FILTER (
        WHERE bbl IS NOT NULL
    ) AS incidents_with_bbl,

    COUNT(*) FILTER (
        WHERE bbl IS NOT NULL
          AND bbl IN (
              SELECT bbl
              FROM core.parcels
          )
    ) AS incidents_with_matching_parcel,

    COUNT(*) FILTER (
        WHERE bbl IS NULL
    ) AS incidents_without_bbl,

    COUNT(*) FILTER (
        WHERE bbl IS NOT NULL
          AND bbl NOT IN (
              SELECT bbl
              FROM core.parcels
          )
    ) AS incidents_with_unmatched_bbl

FROM core.incidents;


-- ============================================================
-- 4. INCIDENTS BY LAND USE
-- ============================================================

SELECT
    COALESCE(land_use, 'Unknown') AS land_use,

    COUNT(*) AS parcel_count,

    COUNT(*) FILTER (
        WHERE incident_count > 0
    ) AS parcels_with_incidents,

    SUM(incident_count) AS incident_count,

    ROUND(
        AVG(incident_count),
        2
    ) AS mean_incidents_per_parcel,

    PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY incident_count
        ) AS median_incidents_per_parcel,

    MAX(incident_count) AS max_incidents_per_parcel

FROM analysis.parcel_incident_profiles

GROUP BY land_use

ORDER BY incident_count DESC;


-- ============================================================
-- 5. INCIDENTS BY BOROUGH AND LAND USE
-- ============================================================

SELECT
    borough,
    COALESCE(land_use, 'Unknown') AS land_use,

    COUNT(*) AS parcel_count,

    COUNT(*) FILTER (
        WHERE incident_count > 0
    ) AS parcels_with_incidents,

    SUM(incident_count) AS incident_count,

    ROUND(
        AVG(incident_count),
        2
    ) AS mean_incidents_per_parcel,

    PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY incident_count
        ) AS median_incidents_per_parcel

FROM analysis.parcel_incident_profiles

GROUP BY
    borough,
    land_use

ORDER BY
    borough,
    incident_count DESC;


-- ============================================================
-- 6. TOP PARCELS BY INCIDENT COUNT
--
-- Raw incident volume is reported together with complaint
-- and agency diversity. Incident count should not be
-- interpreted as a risk or service-demand rate.
-- ============================================================

SELECT
    bbl,
    borough,
    address,
    land_use,
    building_class,
    units_res,
    units_total,
    building_area,
    incident_count,
    complaint_type_count,
    agency_count,
    first_incident_at,
    last_incident_at

FROM analysis.parcel_incident_profiles

WHERE incident_count > 0

ORDER BY incident_count DESC

LIMIT 50;


-- ============================================================
-- 7. COMPLAINT CONCENTRATION AT TOP PARCELS
--
-- Measures whether a parcel's incident volume is broadly
-- distributed across complaint types or dominated by one
-- complaint category.
--
-- dominant_complaint_share:
--   incidents from the most common complaint type /
--   total incidents associated with the parcel
--
-- This is intentionally used instead of normalizing incident
-- counts by building area or residential units.
-- ============================================================

WITH complaint_counts AS (
    SELECT
        i.bbl::BIGINT AS bbl,
        i.complaint_type,
        COUNT(*) AS complaint_count
    FROM core.incidents i
    WHERE i.bbl IS NOT NULL
    GROUP BY
        i.bbl::BIGINT,
        i.complaint_type
),

ranked_complaints AS (
    SELECT
        bbl,
        complaint_type,
        complaint_count,
        ROW_NUMBER() OVER (
            PARTITION BY bbl
            ORDER BY complaint_count DESC, complaint_type
        ) AS complaint_rank
    FROM complaint_counts
)

SELECT
    p.bbl,
    p.borough,
    p.address,
    p.land_use,
    p.building_class,
    p.incident_count,
    p.complaint_type_count,
    rc.complaint_type AS dominant_complaint_type,
    rc.complaint_count AS dominant_complaint_count,

    ROUND(
        (
            100.0 * rc.complaint_count
            / NULLIF(p.incident_count, 0)
        )::NUMERIC,
        2
    ) AS dominant_complaint_share_percent

FROM analysis.parcel_incident_profiles p

JOIN ranked_complaints rc
    ON rc.bbl = p.bbl
   AND rc.complaint_rank = 1

WHERE p.incident_count > 0

ORDER BY
    p.incident_count DESC

LIMIT 50;


-- ============================================================
-- 8. SPATIAL PARCEL ASSIGNMENT FOR INCIDENTS WITHOUT BBL
--
-- This is a complementary validation/coverage analysis.
--
-- ST_Within is used rather than a nearest-parcel operation.
-- An incident point must actually fall inside a parcel polygon.
--
-- Incidents already having a valid BBL are excluded here so
-- this measures the additional coverage obtainable spatially.
-- ============================================================

DROP TABLE IF EXISTS analysis.incident_parcel_spatial_assignment;

CREATE TABLE analysis.incident_parcel_spatial_assignment AS
SELECT
    i.incident_id,
    p.bbl,
    i.created_at,
    i.complaint_type,
    i.agency,
    i.borough AS incident_borough,
    p.land_use,
    p.building_class,
    p.geom AS parcel_geom

FROM core.incidents i
JOIN core.parcels p
    ON ST_Within(i.geom, p.geom)

WHERE i.geom IS NOT NULL
  AND i.bbl IS NULL;


CREATE INDEX idx_incident_parcel_spatial_assignment_parcel_geom
    ON analysis.incident_parcel_spatial_assignment
    USING GIST (parcel_geom);

CREATE INDEX idx_incident_parcel_spatial_assignment_incident
    ON analysis.incident_parcel_spatial_assignment (incident_id);

CREATE INDEX idx_incident_parcel_spatial_assignment_bbl
    ON analysis.incident_parcel_spatial_assignment (bbl);


-- ============================================================
-- 9. SPATIAL ASSIGNMENT SUMMARY
-- ============================================================

SELECT
    COUNT(*) AS incidents_spatially_assigned,
    COUNT(DISTINCT incident_id) AS unique_incidents_assigned,
    COUNT(DISTINCT bbl) AS parcels_reached

FROM analysis.incident_parcel_spatial_assignment;


-- ============================================================
-- 10. BBL VS SPATIAL ASSIGNMENT COVERAGE
-- ============================================================

SELECT
    COUNT(*) AS total_spatial_incidents,

    COUNT(*) FILTER (
        WHERE bbl IS NOT NULL
    ) AS incidents_with_bbl,

    COUNT(*) FILTER (
        WHERE bbl IS NULL
    ) AS incidents_without_bbl,

    (
        SELECT COUNT(DISTINCT incident_id)
        FROM analysis.incident_parcel_spatial_assignment
    ) AS incidents_assigned_spatially_without_bbl

FROM core.incidents

WHERE geom IS NOT NULL;


-- ============================================================
-- 11. QUALITY CONTROL
-- ============================================================

SELECT
    COUNT(*) AS parcel_profile_rows,
    COUNT(DISTINCT bbl) AS unique_bbls,

    COUNT(*) FILTER (
        WHERE incident_count IS NULL
    ) AS null_incident_counts,

    COUNT(*) FILTER (
        WHERE incident_count < 0
    ) AS negative_incident_counts

FROM analysis.parcel_incident_profiles;


SELECT
    COUNT(*) AS spatial_assignment_rows,
    COUNT(DISTINCT incident_id) AS unique_incidents,
    COUNT(DISTINCT bbl) AS unique_parcels

FROM analysis.incident_parcel_spatial_assignment;