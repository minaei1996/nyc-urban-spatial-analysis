-- ============================================================
-- 06_integrated_analysis.sql
-- NYC Urban Services, Incidents & Spatial Analysis
--
-- Purpose:
--   Integrate 311 incident density with geographic proximity
--   to the nearest FDNY firehouse.
--
-- Main relationship:
--   incident hotspot -> nearest firehouse
--
-- Hotspots:
--   1,000-ft x 1,000-ft occupied grid cells derived from
--   analysis.incident_hotspots.
--
-- Important:
--   Distance to a firehouse is geographic distance only.
--   It does NOT represent emergency response time, travel time,
--   service coverage, or FDNY operational performance.
--
-- Density thresholds:
--   Top 10% = High
--   Top 5%  = Very High
--   Top 1%  = Extreme
--
-- These classifications are empirical and are not official
-- FDNY standards.
--
-- CRS:
--   EPSG:2263 - NAD83 / New York Long Island (ftUS)
-- ============================================================


-- ============================================================
-- 1. CREATE INTEGRATED HOTSPOT PROFILES
-- ============================================================
--
-- Each occupied incident hotspot is assigned to its nearest
-- firehouse using a KNN spatial search.
--
-- Incident density is normalized to a square-mile equivalent
-- because each hotspot represents a 1,000-ft x 1,000-ft cell.
--
-- 1,000 ft x 1,000 ft = 1,000,000 ft²
-- 1 square mile = 27,878,400 ft²
-- Conversion factor = 27.8784
--
-- The source 311 dataset represents 2021, so the normalized
-- value is expressed as annual incidents per square mile.
-- ============================================================

DROP TABLE IF EXISTS analysis.integrated_hotspot_profiles;

CREATE TABLE analysis.integrated_hotspot_profiles AS

WITH thresholds AS (
    SELECT
        PERCENTILE_CONT(0.90)
            WITHIN GROUP (ORDER BY incident_count) AS p90,

        PERCENTILE_CONT(0.95)
            WITHIN GROUP (ORDER BY incident_count) AS p95,

        PERCENTILE_CONT(0.99)
            WITHIN GROUP (ORDER BY incident_count) AS p99

    FROM analysis.incident_hotspots
),

hotspots AS (
    SELECT
        h.hotspot_id,
        h.incident_count,
        h.unique_incident_count,
        h.geom,

        CASE
            WHEN h.incident_count >= t.p99
                THEN 'Extreme'

            WHEN h.incident_count >= t.p95
                THEN 'Very High'

            WHEN h.incident_count >= t.p90
                THEN 'High'

            ELSE 'Other'
        END AS density_class,

        ROUND(
            (
                h.incident_count::NUMERIC
                * 27.8784
            ),
            2
        ) AS annual_incidents_per_square_mile

    FROM analysis.incident_hotspots h
    CROSS JOIN thresholds t
)

SELECT
    h.hotspot_id,
    h.incident_count,
    h.unique_incident_count,
    h.geom,

    h.density_class,
    h.annual_incidents_per_square_mile,

    f.firehouse_id,
    f.facility_name,
    f.address AS firehouse_address,
    f.borough AS firehouse_borough,

    ST_Distance(
        ST_Centroid(h.geom),
        f.geom
    ) AS distance_ft,

    ROUND(
        (
            ST_Distance(
                ST_Centroid(h.geom),
                f.geom
            ) / 5280.0
        )::NUMERIC,
        3
    ) AS distance_miles

FROM hotspots h

CROSS JOIN LATERAL (
    SELECT
        firehouse_id,
        facility_name,
        address,
        borough,
        geom

    FROM core.firehouses

    ORDER BY
        geom <-> ST_Centroid(h.geom)

    LIMIT 1
) f;


CREATE INDEX idx_integrated_hotspot_profiles_geom
    ON analysis.integrated_hotspot_profiles
    USING GIST (geom);

CREATE INDEX idx_integrated_hotspot_profiles_firehouse
    ON analysis.integrated_hotspot_profiles (firehouse_id);

CREATE INDEX idx_integrated_hotspot_profiles_density
    ON analysis.integrated_hotspot_profiles (density_class);

CREATE INDEX idx_integrated_hotspot_profiles_distance
    ON analysis.integrated_hotspot_profiles (distance_ft);

ANALYZE analysis.integrated_hotspot_profiles;


-- ============================================================
-- 2. SUMMARY BY INCIDENT DENSITY CLASS
-- ============================================================
--
-- Compares incident density classes with geographic distance
-- to the nearest firehouse.
-- ============================================================

SELECT
    density_class,

    COUNT(*) AS hotspot_cells,

    SUM(incident_count) AS incidents,

    ROUND(
        AVG(annual_incidents_per_square_mile)::NUMERIC,
        2
    ) AS mean_annual_incidents_per_square_mile,

    ROUND(
        AVG(distance_miles)::NUMERIC,
        3
    ) AS mean_firehouse_distance_miles,

    ROUND(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (
            ORDER BY distance_miles
        )::NUMERIC,
        3
    ) AS median_firehouse_distance_miles,

    ROUND(
        PERCENTILE_CONT(0.90)
        WITHIN GROUP (
            ORDER BY distance_miles
        )::NUMERIC,
        3
    ) AS p90_firehouse_distance_miles

FROM analysis.integrated_hotspot_profiles

GROUP BY density_class

ORDER BY
    CASE density_class
        WHEN 'Extreme' THEN 1
        WHEN 'Very High' THEN 2
        WHEN 'High' THEN 3
        WHEN 'Other' THEN 4
    END;


-- ============================================================
-- 3. HIGH-DENSITY HOTSPOTS MORE THAN 1 MILE FROM A FIREHOUSE
-- ============================================================
--
-- Identifies high-density hotspot cells that are geographically
-- more than one mile from their nearest firehouse.
--
-- >1 mile is an analytical threshold only. It is NOT an FDNY
-- service-distance or response-time standard.
-- ============================================================

DROP TABLE IF EXISTS analysis.distant_high_density_hotspots;

CREATE TABLE analysis.distant_high_density_hotspots AS

SELECT
    *
FROM analysis.integrated_hotspot_profiles

WHERE density_class IN (
    'Extreme',
    'Very High',
    'High'
)

AND distance_miles > 1.00;


CREATE INDEX idx_distant_high_density_hotspots_geom
    ON analysis.distant_high_density_hotspots
    USING GIST (geom);

CREATE INDEX idx_distant_high_density_hotspots_firehouse
    ON analysis.distant_high_density_hotspots (firehouse_id);

ANALYZE analysis.distant_high_density_hotspots;


SELECT
    COUNT(*) AS hotspot_cells,

    COALESCE(
        SUM(incident_count),
        0
    ) AS incidents,

    ROUND(
        AVG(distance_miles)::NUMERIC,
        3
    ) AS mean_firehouse_distance_miles,

    ROUND(
        MAX(distance_miles)::NUMERIC,
        3
    ) AS max_firehouse_distance_miles

FROM analysis.distant_high_density_hotspots;


-- ============================================================
-- 4. EXTREME HOTSPOTS BY FIREHOUSE DISTANCE
-- ============================================================
--
-- Lists the highest-density hotspot cells and their nearest
-- firehouse distances.
-- ============================================================

SELECT
    hotspot_id,
    incident_count,

    annual_incidents_per_square_mile,

    firehouse_id,
    facility_name,

    ROUND(
        distance_miles::NUMERIC,
        3
    ) AS distance_miles

FROM analysis.integrated_hotspot_profiles

WHERE density_class = 'Extreme'

ORDER BY
    distance_miles DESC,
    incident_count DESC;


-- ============================================================
-- 5. ALL HIGH-DENSITY HOTSPOTS BY FIREHOUSE DISTANCE
-- ============================================================
--
-- Provides a detailed inspection list for High, Very High,
-- and Extreme hotspot cells.
-- ============================================================

SELECT
    hotspot_id,
    density_class,
    incident_count,

    annual_incidents_per_square_mile,

    firehouse_id,
    facility_name,

    ROUND(
        distance_miles::NUMERIC,
        3
    ) AS distance_miles

FROM analysis.integrated_hotspot_profiles

WHERE density_class IN (
    'Extreme',
    'Very High',
    'High'
)

ORDER BY
    distance_miles DESC,
    incident_count DESC;


-- ============================================================
-- 6. HIGH-DENSITY HOTSPOTS BY NEAREST FIREHOUSE
-- ============================================================
--
-- Shows how high-density hotspot cells are geographically
-- associated with individual firehouses.
--
-- This is a spatial allocation result. It does not represent
-- firehouse workload, dispatch volume, or response demand.
-- ============================================================

DROP TABLE IF EXISTS analysis.firehouse_hotspot_profiles;

CREATE TABLE analysis.firehouse_hotspot_profiles AS

SELECT
    firehouse_id,
    facility_name,
    firehouse_address,
    firehouse_borough,

    COUNT(*) AS hotspot_cells,

    SUM(incident_count) AS incidents_in_hotspot_cells,

    ROUND(
        AVG(distance_miles)::NUMERIC,
        3
    ) AS mean_hotspot_distance_miles,

    ROUND(
        MAX(distance_miles)::NUMERIC,
        3
    ) AS max_hotspot_distance_miles,

    COUNT(*) FILTER (
        WHERE density_class = 'Extreme'
    ) AS extreme_hotspot_cells,

    COUNT(*) FILTER (
        WHERE density_class = 'Very High'
    ) AS very_high_hotspot_cells,

    COUNT(*) FILTER (
        WHERE density_class = 'High'
    ) AS high_hotspot_cells

FROM analysis.integrated_hotspot_profiles

WHERE density_class IN (
    'Extreme',
    'Very High',
    'High'
)

GROUP BY
    firehouse_id,
    facility_name,
    firehouse_address,
    firehouse_borough;


CREATE INDEX idx_firehouse_hotspot_profiles_firehouse
    ON analysis.firehouse_hotspot_profiles (firehouse_id);

CREATE INDEX idx_firehouse_hotspot_profiles_borough
    ON analysis.firehouse_hotspot_profiles (firehouse_borough);

ANALYZE analysis.firehouse_hotspot_profiles;


-- ============================================================
-- 7. HIGH-DENSITY HOTSPOTS BY NEAREST FIREHOUSE BOROUGH
-- ============================================================
--
-- Groups hotspot cells according to the borough of their
-- nearest firehouse.
--
-- IMPORTANT:
--   "firehouse_borough" is the borough containing the nearest
--   firehouse. It is not necessarily the borough containing
--   the hotspot itself.
--
-- This distinction avoids implying that firehouse assignment
-- represents administrative or geographic borough boundaries.
-- ============================================================

SELECT
    h.firehouse_borough,

    COUNT(*) AS hotspot_cells,

    SUM(h.incident_count) AS incidents,

    ROUND(
        AVG(h.distance_miles)::NUMERIC,
        3
    ) AS mean_firehouse_distance_miles,

    ROUND(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (
            ORDER BY h.distance_miles
        )::NUMERIC,
        3
    ) AS median_firehouse_distance_miles,

    ROUND(
        PERCENTILE_CONT(0.90)
        WITHIN GROUP (
            ORDER BY h.distance_miles
        )::NUMERIC,
        3
    ) AS p90_firehouse_distance_miles,

    COUNT(*) FILTER (
        WHERE h.distance_miles > 1.00
    ) AS hotspot_cells_beyond_1_mile,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE h.distance_miles > 1.00
        )
        / COUNT(*)::NUMERIC,
        2
    ) AS percent_beyond_1_mile

FROM analysis.integrated_hotspot_profiles h

WHERE h.density_class IN (
    'Extreme',
    'Very High',
    'High'
)

GROUP BY
    h.firehouse_borough

ORDER BY
    h.firehouse_borough;


-- ============================================================
-- 8. DISTANCE DISTRIBUTION OF HIGH-DENSITY HOTSPOTS
-- ============================================================
--
-- Summarizes high-density hotspot cells using distance bands.
--
-- This provides a more interpretable complement to the
-- >1-mile screening analysis.
-- ============================================================

SELECT
    CASE
        WHEN distance_miles <= 0.25
            THEN '0-0.25 mi'

        WHEN distance_miles <= 0.50
            THEN '0.25-0.50 mi'

        WHEN distance_miles <= 1.00
            THEN '0.50-1.00 mi'

        WHEN distance_miles <= 2.00
            THEN '1.00-2.00 mi'

        ELSE '>2.00 mi'
    END AS distance_class,

    COUNT(*) AS hotspot_cells,

    SUM(incident_count) AS incidents,

    ROUND(
        AVG(incident_count)::NUMERIC,
        2
    ) AS mean_incidents_per_hotspot

FROM analysis.integrated_hotspot_profiles

WHERE density_class IN (
    'Extreme',
    'Very High',
    'High'
)

GROUP BY
    CASE
        WHEN distance_miles <= 0.25
            THEN '0-0.25 mi'

        WHEN distance_miles <= 0.50
            THEN '0.25-0.50 mi'

        WHEN distance_miles <= 1.00
            THEN '0.50-1.00 mi'

        WHEN distance_miles <= 2.00
            THEN '1.00-2.00 mi'

        ELSE '>2.00 mi'
    END

ORDER BY
    MIN(distance_miles);


-- ============================================================
-- 9. FINAL QUALITY CONTROL
-- ============================================================

SELECT
    COUNT(*) AS integrated_hotspots,

    COUNT(DISTINCT hotspot_id) AS unique_hotspots,

    COUNT(*) FILTER (
        WHERE firehouse_id IS NULL
    ) AS missing_firehouse,

    COUNT(*) FILTER (
        WHERE distance_ft IS NULL
    ) AS missing_distance,

    COUNT(*) FILTER (
        WHERE distance_ft < 0
    ) AS negative_distances,

    COUNT(*) FILTER (
        WHERE density_class IS NULL
    ) AS missing_density_class

FROM analysis.integrated_hotspot_profiles;


-- The number of integrated hotspot records should equal
-- the number of source hotspot records.

SELECT
    (
        SELECT COUNT(*)
        FROM analysis.incident_hotspots
    ) AS source_hotspots,

    (
        SELECT COUNT(*)
        FROM analysis.integrated_hotspot_profiles
    ) AS integrated_hotspots;


-- Verify that every integrated hotspot has exactly one
-- nearest firehouse assignment.

SELECT
    hotspot_id,
    COUNT(*) AS assignment_count

FROM analysis.integrated_hotspot_profiles

GROUP BY hotspot_id

HAVING COUNT(*) <> 1;


-- ============================================================
-- End of 06_integrated_analysis.sql
-- ============================================================