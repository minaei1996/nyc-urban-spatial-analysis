-- ============================================================
-- 05_pharmacy_accessibility.sql
-- NYC Urban Services, Incidents & Spatial Analysis
--
-- Purpose:
-- Analyze the spatial accessibility of NYC parcels to the
-- available Rite Aid pharmacy locations.
--
-- Main relationship:
--   core.pharmacies.bbl -> core.parcels.bbl
--
-- Pharmacy accessibility is measured using straight-line
-- distance from each parcel to its nearest pharmacy.
--
-- Important limitation:
--   This dataset contains Rite Aid locations only. Therefore,
--   results describe proximity to Rite Aid locations and should
--   not be interpreted as complete pharmacy or healthcare access.
-- ============================================================


-- ============================================================
-- 1. PHARMACY-PARCEL LINKAGE QC
-- ============================================================

SELECT
    COUNT(*) AS pharmacy_count,

    COUNT(*) FILTER (
        WHERE bbl IS NOT NULL
    ) AS pharmacies_with_bbl,

    COUNT(*) FILTER (
        WHERE bbl IN (
            SELECT bbl
            FROM core.parcels
        )
    ) AS pharmacies_with_matching_parcel,

    COUNT(*) FILTER (
        WHERE geom IS NOT NULL
    ) AS pharmacies_with_geometry

FROM core.pharmacies;


-- ============================================================
-- 2. PHARMACY-PARCEL LINKAGE DETAILS
-- ============================================================

SELECT
    ph.pharmacy_id,
    ph.pharm_id,
    ph.name,
    ph.bbl AS pharmacy_bbl,
    p.borough,
    p.address,
    p.land_use,
    p.building_class

FROM core.pharmacies ph

LEFT JOIN core.parcels p
    ON p.bbl = ph.bbl

ORDER BY
    p.borough,
    p.address;


-- ============================================================
-- 3. NEAREST PHARMACY FOR EACH PARCEL
--
-- KNN (<->) is used to efficiently identify the nearest
-- pharmacy using the projected EPSG:2263 geometries.
--
-- Distance is reported in miles.
-- ============================================================

DROP TABLE IF EXISTS analysis.parcel_pharmacy_accessibility;

CREATE TABLE analysis.parcel_pharmacy_accessibility AS
SELECT
    p.bbl,
    p.borough,
    p.address,
    p.land_use,
    p.building_class,

    p.incident_count,

    ph.pharmacy_id,
    ph.pharm_id,
    ph.name AS pharmacy_name,

    ST_Distance(
        p.geom,
        ph.geom
    ) / 5280.0 AS nearest_pharmacy_distance_miles,

    p.geom AS parcel_geom

FROM analysis.parcel_incident_profiles p

CROSS JOIN LATERAL (
    SELECT
        pharmacy_id,
        pharm_id,
        name,
        geom

    FROM core.pharmacies

    WHERE geom IS NOT NULL

    ORDER BY
        p.geom <-> geom

    LIMIT 1
) ph

WHERE p.geom IS NOT NULL;


CREATE INDEX idx_parcel_pharmacy_accessibility_geom
    ON analysis.parcel_pharmacy_accessibility
    USING GIST (parcel_geom);

CREATE INDEX idx_parcel_pharmacy_accessibility_bbl
    ON analysis.parcel_pharmacy_accessibility (bbl);

CREATE INDEX idx_parcel_pharmacy_accessibility_distance
    ON analysis.parcel_pharmacy_accessibility
    (nearest_pharmacy_distance_miles);


-- ============================================================
-- 4. PARCEL PHARMACY ACCESSIBILITY SUMMARY
-- ============================================================

SELECT
    COUNT(*) AS parcel_count,

    ROUND(
        AVG(nearest_pharmacy_distance_miles)::NUMERIC,
        3
    ) AS mean_distance_miles,

    PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY nearest_pharmacy_distance_miles
        ) AS median_distance_miles,

    PERCENTILE_CONT(0.9)
        WITHIN GROUP (
            ORDER BY nearest_pharmacy_distance_miles
        ) AS p90_distance_miles,

    PERCENTILE_CONT(0.95)
        WITHIN GROUP (
            ORDER BY nearest_pharmacy_distance_miles
        ) AS p95_distance_miles,

    MAX(nearest_pharmacy_distance_miles) AS max_distance_miles

FROM analysis.parcel_pharmacy_accessibility;


-- ============================================================
-- 5. PHARMACY DISTANCE CLASSES
--
-- These are geographic distance classes, not formal
-- healthcare-access standards.
-- ============================================================

SELECT
    CASE
        WHEN nearest_pharmacy_distance_miles <= 0.25
            THEN '0-0.25 mi'
        WHEN nearest_pharmacy_distance_miles <= 0.50
            THEN '0.25-0.50 mi'
        WHEN nearest_pharmacy_distance_miles <= 1.00
            THEN '0.50-1.00 mi'
        WHEN nearest_pharmacy_distance_miles <= 2.00
            THEN '1.00-2.00 mi'
        ELSE '>2.00 mi'
    END AS distance_class,

    COUNT(*) AS parcel_count,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS parcel_share_percent,

    ROUND(
        AVG(incident_count)::NUMERIC,
        2
    ) AS mean_incidents_per_parcel

FROM analysis.parcel_pharmacy_accessibility

GROUP BY
    CASE
        WHEN nearest_pharmacy_distance_miles <= 0.25
            THEN '0-0.25 mi'
        WHEN nearest_pharmacy_distance_miles <= 0.50
            THEN '0.25-0.50 mi'
        WHEN nearest_pharmacy_distance_miles <= 1.00
            THEN '0.50-1.00 mi'
        WHEN nearest_pharmacy_distance_miles <= 2.00
            THEN '1.00-2.00 mi'
        ELSE '>2.00 mi'
    END

ORDER BY
    MIN(nearest_pharmacy_distance_miles);


-- ============================================================
-- 6. PHARMACY ACCESSIBILITY BY BOROUGH
-- ============================================================

SELECT
    borough,

    COUNT(*) AS parcel_count,

    ROUND(
        AVG(nearest_pharmacy_distance_miles)::NUMERIC,
        3
    ) AS mean_distance_miles,

    PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY nearest_pharmacy_distance_miles
        ) AS median_distance_miles,

    PERCENTILE_CONT(0.9)
        WITHIN GROUP (
            ORDER BY nearest_pharmacy_distance_miles
        ) AS p90_distance_miles,

    COUNT(*) FILTER (
        WHERE nearest_pharmacy_distance_miles <= 0.50
    ) AS parcels_within_0_5_miles,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE nearest_pharmacy_distance_miles <= 0.50
        )
        / COUNT(*),
        2
    ) AS share_within_0_5_miles_percent

FROM analysis.parcel_pharmacy_accessibility

GROUP BY borough

ORDER BY borough;


-- ============================================================
-- 7. HIGH-INCIDENT PARCELS WITH GREATER RITE AID DISTANCE
--
-- Identifies parcels with 311 incident activity that are also
-- geographically distant from the nearest Rite Aid location.
--
-- This is a spatial screening result. It does not represent
-- unmet healthcare demand or inadequate pharmacy service.
-- ============================================================

SELECT
    bbl,
    borough,
    address,
    land_use,
    building_class,
    incident_count,
    pharmacy_id,
    pharmacy_name,

    ROUND(
        nearest_pharmacy_distance_miles::NUMERIC,
        3
    ) AS nearest_pharmacy_distance_miles

FROM analysis.parcel_pharmacy_accessibility

WHERE incident_count > 0
  AND nearest_pharmacy_distance_miles > 1.0

ORDER BY
    incident_count DESC

LIMIT 50;


-- ============================================================
-- 8. HIGH-INCIDENT PARCELS BY RITE AID DISTANCE
--
-- Restricts the analysis to parcels with substantial incident
-- activity so the result is not dominated by parcels with very
-- few incidents.
--
-- The threshold is empirical: the top 5% of incident-active
-- parcels.
-- ============================================================

WITH incident_active_parcels AS (
    SELECT
        PERCENTILE_CONT(0.95)
            WITHIN GROUP (
                ORDER BY incident_count
            ) AS incident_p95

    FROM analysis.parcel_pharmacy_accessibility

    WHERE incident_count > 0
)

SELECT
    a.bbl,
    a.borough,
    a.address,
    a.land_use,
    a.building_class,
    a.incident_count,
    a.pharmacy_id,
    a.pharmacy_name,

    ROUND(
        a.nearest_pharmacy_distance_miles::NUMERIC,
        3
    ) AS nearest_pharmacy_distance_miles

FROM analysis.parcel_pharmacy_accessibility a

CROSS JOIN incident_active_parcels t

WHERE a.incident_count >= t.incident_p95

ORDER BY
    a.nearest_pharmacy_distance_miles DESC

LIMIT 50;


-- ============================================================
-- 9. INCIDENTS ASSOCIATED WITH PARCELS BY RITE AID DISTANCE
--
-- Counts 311 incidents through their BBL-linked parcels.
--
-- This does not spatially assign incidents without a BBL.
-- ============================================================

SELECT
    CASE
        WHEN nearest_pharmacy_distance_miles <= 0.25
            THEN '0-0.25 mi'
        WHEN nearest_pharmacy_distance_miles <= 0.50
            THEN '0.25-0.50 mi'
        WHEN nearest_pharmacy_distance_miles <= 1.00
            THEN '0.50-1.00 mi'
        WHEN nearest_pharmacy_distance_miles <= 2.00
            THEN '1.00-2.00 mi'
        ELSE '>2.00 mi'
    END AS distance_class,

    COUNT(*) AS parcel_count,

    SUM(incident_count) AS linked_incident_count,

    COUNT(*) FILTER (
        WHERE incident_count > 0
    ) AS parcels_with_incidents,

    ROUND(
        AVG(incident_count)::NUMERIC,
        2
    ) AS mean_incidents_per_parcel

FROM analysis.parcel_pharmacy_accessibility

GROUP BY
    CASE
        WHEN nearest_pharmacy_distance_miles <= 0.25
            THEN '0-0.25 mi'
        WHEN nearest_pharmacy_distance_miles <= 0.50
            THEN '0.25-0.50 mi'
        WHEN nearest_pharmacy_distance_miles <= 1.00
            THEN '0.50-1.00 mi'
        WHEN nearest_pharmacy_distance_miles <= 2.00
            THEN '1.00-2.00 mi'
        ELSE '>2.00 mi'
    END

ORDER BY
    MIN(nearest_pharmacy_distance_miles);


-- ============================================================
-- 10. RITE AID PARCEL ASSOCIATION
--
-- Shows how many parcels are geographically nearest to each
-- Rite Aid location.
--
-- This describes spatial allocation of parcels to the available
-- Rite Aid locations. It does not represent actual utilization,
-- customer volume, or pharmacy catchment areas.
-- ============================================================

SELECT
    pharmacy_id,
    pharmacy_name,

    COUNT(*) AS nearest_parcel_count,

    SUM(incident_count) AS linked_incident_count,

    ROUND(
        AVG(nearest_pharmacy_distance_miles)::NUMERIC,
        3
    ) AS mean_assigned_distance_miles

FROM analysis.parcel_pharmacy_accessibility

GROUP BY
    pharmacy_id,
    pharmacy_name

ORDER BY
    nearest_parcel_count DESC;


-- ============================================================
-- 11. QUALITY CONTROL
-- ============================================================

SELECT
    COUNT(*) AS accessibility_rows,
    COUNT(DISTINCT bbl) AS unique_parcels,

    COUNT(*) FILTER (
        WHERE nearest_pharmacy_distance_miles IS NULL
    ) AS null_distances,

    COUNT(*) FILTER (
        WHERE nearest_pharmacy_distance_miles < 0
    ) AS negative_distances

FROM analysis.parcel_pharmacy_accessibility;


SELECT
    COUNT(*) AS pharmacy_count,
    COUNT(DISTINCT pharmacy_id) AS unique_pharmacies,

    COUNT(*) FILTER (
        WHERE geom IS NULL
    ) AS null_geometries

FROM core.pharmacies;