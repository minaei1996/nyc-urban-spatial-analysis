-- ============================================================
-- Analysis: Firehouse Accessibility
-- Source tables:
--   core.firehouses
--   core.incidents
--   core.parcels
--
-- Purpose:
--   Measure spatial proximity to FDNY firehouses using
--   nearest-neighbor and distance-based analysis.
--
-- Important interpretation:
--   These results measure geographic distance to firehouses.
--   They do NOT represent emergency response time, travel time,
--   traffic conditions, station availability, or dispatch behavior.
--
-- CRS:
--   EPSG:2263 - NAD83 / New York Long Island (ftUS)
--   Distances are calculated in feet and converted to miles.
-- ============================================================


-- ============================================================
-- 1. Nearest firehouse for each incident
-- ============================================================
--
-- Only incidents with valid spatial geometry are included.
-- The LATERAL KNN query uses the GiST index on firehouse geometry.
--

DROP TABLE IF EXISTS analysis.incident_firehouse_accessibility;

CREATE TABLE analysis.incident_firehouse_accessibility AS
SELECT
    i.incident_id,
    i.created_at,
    i.complaint_type,
    i.agency,
    i.borough,
    i.geom,

    f.firehouse_id,
    f.facility_name,
    f.borough AS firehouse_borough,
    f.address,

    ST_Distance(i.geom, f.geom) AS distance_ft,
    ROUND(
        (ST_Distance(i.geom, f.geom) / 5280.0)::NUMERIC,
        3
    ) AS distance_miles

FROM core.incidents i
CROSS JOIN LATERAL (
    SELECT
        firehouse_id,
        facility_name,
        borough,
        address,
        geom
    FROM core.firehouses
    ORDER BY geom <-> i.geom
    LIMIT 1
) f
WHERE i.geom IS NOT NULL;


CREATE INDEX idx_incident_firehouse_accessibility_geom
    ON analysis.incident_firehouse_accessibility
    USING GIST (geom);

CREATE INDEX idx_incident_firehouse_accessibility_firehouse
    ON analysis.incident_firehouse_accessibility (firehouse_id);

CREATE INDEX idx_incident_firehouse_accessibility_borough
    ON analysis.incident_firehouse_accessibility (borough);

CREATE INDEX idx_incident_firehouse_accessibility_distance
    ON analysis.incident_firehouse_accessibility (distance_ft);

ANALYZE analysis.incident_firehouse_accessibility;


-- ============================================================
-- 2. Incident accessibility summary
-- ============================================================

SELECT
    COUNT(*) AS spatial_incidents,
    COUNT(DISTINCT firehouse_id) AS firehouses_serving_nearest_incident,
    ROUND(AVG(distance_ft)::NUMERIC, 2) AS mean_distance_ft,
    ROUND(AVG(distance_miles)::NUMERIC, 3) AS mean_distance_miles,
    ROUND(MIN(distance_miles)::NUMERIC, 3) AS min_distance_miles,
    ROUND(MAX(distance_miles)::NUMERIC, 3) AS max_distance_miles,
    ROUND(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY distance_miles)::NUMERIC,
        3
    ) AS median_distance_miles,
    ROUND(
        PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY distance_miles)::NUMERIC,
        3
    ) AS p90_distance_miles,
    ROUND(
        PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY distance_miles)::NUMERIC,
        3
    ) AS p95_distance_miles
FROM analysis.incident_firehouse_accessibility;


-- ============================================================
-- 3. Distance-based accessibility classes
-- ============================================================
--
-- These are analytical distance bands, not official FDNY
-- service standards.
--

DROP TABLE IF EXISTS analysis.incident_firehouse_accessibility_classes;

CREATE TABLE analysis.incident_firehouse_accessibility_classes AS
SELECT
    a.*,
    CASE
        WHEN distance_miles <= 0.25 THEN '0-0.25 mi'
        WHEN distance_miles <= 0.50 THEN '0.25-0.50 mi'
        WHEN distance_miles <= 1.00 THEN '0.50-1.00 mi'
        WHEN distance_miles <= 2.00 THEN '1.00-2.00 mi'
        ELSE '>2.00 mi'
    END AS accessibility_class
FROM analysis.incident_firehouse_accessibility a;


CREATE INDEX idx_incident_firehouse_accessibility_classes_geom
    ON analysis.incident_firehouse_accessibility_classes
    USING GIST (geom);

CREATE INDEX idx_incident_firehouse_accessibility_classes_class
    ON analysis.incident_firehouse_accessibility_classes
    (accessibility_class);

ANALYZE analysis.incident_firehouse_accessibility_classes;


-- Distribution of incidents by distance band

SELECT
    accessibility_class,
    COUNT(*) AS incident_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percent_of_incidents
FROM analysis.incident_firehouse_accessibility_classes
GROUP BY accessibility_class
ORDER BY
    CASE accessibility_class
        WHEN '0-0.25 mi' THEN 1
        WHEN '0.25-0.50 mi' THEN 2
        WHEN '0.50-1.00 mi' THEN 3
        WHEN '1.00-2.00 mi' THEN 4
        WHEN '>2.00 mi' THEN 5
    END;


-- ============================================================
-- 4. Firehouse-level incident proximity profile
-- ============================================================
--
-- Shows how many incidents have each firehouse as their
-- nearest station and the corresponding distance distribution.
--

DROP TABLE IF EXISTS analysis.firehouse_incident_profiles;

CREATE TABLE analysis.firehouse_incident_profiles AS
SELECT
    f.firehouse_id,
    f.facility_name,
    f.address,
    f.borough,

    COUNT(a.incident_id) AS nearest_incident_count,

    ROUND(
        AVG(a.distance_miles)::NUMERIC,
        3
    ) AS mean_incident_distance_miles,

    ROUND(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY a.distance_miles)::NUMERIC,
        3
    ) AS median_incident_distance_miles,

    ROUND(
        PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY a.distance_miles)::NUMERIC,
        3
    ) AS p90_incident_distance_miles,

    ROUND(
        MAX(a.distance_miles)::NUMERIC,
        3
    ) AS max_incident_distance_miles

FROM core.firehouses f
LEFT JOIN analysis.incident_firehouse_accessibility a
    ON a.firehouse_id = f.firehouse_id

GROUP BY
    f.firehouse_id,
    f.facility_name,
    f.address,
    f.borough;


CREATE INDEX idx_firehouse_incident_profiles_borough
    ON analysis.firehouse_incident_profiles (borough);

ANALYZE analysis.firehouse_incident_profiles;


-- ============================================================
-- 5. Incident accessibility by borough
-- ============================================================

DROP TABLE IF EXISTS analysis.firehouse_accessibility_borough;

CREATE TABLE analysis.firehouse_accessibility_borough AS
SELECT
    borough,

    COUNT(*) AS incident_count,

    ROUND(
        AVG(distance_miles)::NUMERIC,
        3
    ) AS mean_distance_miles,

    ROUND(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY distance_miles)::NUMERIC,
        3
    ) AS median_distance_miles,

    ROUND(
        PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY distance_miles)::NUMERIC,
        3
    ) AS p90_distance_miles,

    COUNT(*) FILTER (
        WHERE distance_miles <= 0.50
    ) AS incidents_within_0_5_miles,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE distance_miles <= 0.50
        ) / COUNT(*)::NUMERIC,
        2
    ) AS percent_within_0_5_miles,

    COUNT(*) FILTER (
        WHERE distance_miles > 2.00
    ) AS incidents_beyond_2_miles,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE distance_miles > 2.00
        ) / COUNT(*)::NUMERIC,
        2
    ) AS percent_beyond_2_miles

FROM analysis.incident_firehouse_accessibility

GROUP BY borough
ORDER BY borough;


-- ============================================================
-- 6. Parcel-level firehouse accessibility
-- ============================================================
--
-- Unlike incidents, parcels represent the underlying spatial
-- distribution of properties. This provides a second,
-- independent accessibility perspective.
--

DROP TABLE IF EXISTS analysis.parcel_firehouse_accessibility;

CREATE TABLE analysis.parcel_firehouse_accessibility AS
SELECT
    p.bbl,
    p.borough,
    p.address,
    p.land_use,
    p.building_class,
    p.lot_area,
    p.building_area,
    p.units_res,
    p.units_total,
    p.geom,

    f.firehouse_id,
    f.facility_name,
    f.borough AS firehouse_borough,

    ST_Distance(
        ST_PointOnSurface(p.geom),
        f.geom
    ) AS distance_ft,

    ROUND(
        (
            ST_Distance(
                ST_PointOnSurface(p.geom),
                f.geom
            ) / 5280.0
        )::NUMERIC,
        3
    ) AS distance_miles

FROM core.parcels p

CROSS JOIN LATERAL (
    SELECT
        firehouse_id,
        facility_name,
        borough,
        geom
    FROM core.firehouses
    ORDER BY geom <-> ST_PointOnSurface(p.geom)
    LIMIT 1
) f

WHERE p.geom IS NOT NULL;


CREATE INDEX idx_parcel_firehouse_accessibility_geom
    ON analysis.parcel_firehouse_accessibility
    USING GIST (geom);

CREATE INDEX idx_parcel_firehouse_accessibility_firehouse
    ON analysis.parcel_firehouse_accessibility (firehouse_id);

CREATE INDEX idx_parcel_firehouse_accessibility_borough
    ON analysis.parcel_firehouse_accessibility (borough);

CREATE INDEX idx_parcel_firehouse_accessibility_distance
    ON analysis.parcel_firehouse_accessibility (distance_ft);

ANALYZE analysis.parcel_firehouse_accessibility;


-- ============================================================
-- 7. Parcel accessibility summary
-- ============================================================

SELECT
    COUNT(*) AS parcel_count,

    ROUND(
        AVG(distance_miles)::NUMERIC,
        3
    ) AS mean_distance_miles,

    ROUND(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY distance_miles)::NUMERIC,
        3
    ) AS median_distance_miles,

    ROUND(
        PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY distance_miles)::NUMERIC,
        3
    ) AS p90_distance_miles,

    COUNT(*) FILTER (
        WHERE distance_miles <= 0.50
    ) AS parcels_within_0_5_miles,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE distance_miles <= 0.50
        ) / COUNT(*)::NUMERIC,
        2
    ) AS percent_within_0_5_miles,

    COUNT(*) FILTER (
        WHERE distance_miles > 2.00
    ) AS parcels_beyond_2_miles,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE distance_miles > 2.00
        ) / COUNT(*)::NUMERIC,
        2
    ) AS percent_beyond_2_miles

FROM analysis.parcel_firehouse_accessibility;


-- ============================================================
-- 8. Parcel accessibility by borough
-- ============================================================

SELECT
    borough,
    COUNT(*) AS parcel_count,

    ROUND(
        AVG(distance_miles)::NUMERIC,
        3
    ) AS mean_distance_miles,

    ROUND(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY distance_miles)::NUMERIC,
        3
    ) AS median_distance_miles,

    ROUND(
        PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY distance_miles)::NUMERIC,
        3
    ) AS p90_distance_miles,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE distance_miles <= 0.50
        ) / COUNT(*)::NUMERIC,
        2
    ) AS percent_within_0_5_miles,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE distance_miles > 2.00
        ) / COUNT(*)::NUMERIC,
        2
    ) AS percent_beyond_2_miles

FROM analysis.parcel_firehouse_accessibility

GROUP BY borough
ORDER BY borough;


-- ============================================================
-- 9. Parcel accessibility by land-use category
-- ============================================================

SELECT
    land_use,
    COUNT(*) AS parcel_count,

    ROUND(
        AVG(distance_miles)::NUMERIC,
        3
    ) AS mean_distance_miles,

    ROUND(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY distance_miles)::NUMERIC,
        3
    ) AS median_distance_miles,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE distance_miles <= 0.50
        ) / COUNT(*)::NUMERIC,
        2
    ) AS percent_within_0_5_miles,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE distance_miles > 2.00
        ) / COUNT(*)::NUMERIC,
        2
    ) AS percent_beyond_2_miles

FROM analysis.parcel_firehouse_accessibility

GROUP BY land_use
ORDER BY parcel_count DESC;


-- ============================================================
-- 10. Firehouse service-area style counts
-- ============================================================
--
-- These are simple Euclidean buffers around firehouses.
-- They should NOT be interpreted as actual FDNY service areas.
--

DROP TABLE IF EXISTS analysis.firehouse_distance_buffers;

CREATE TABLE analysis.firehouse_distance_buffers AS
SELECT
    firehouse_id,
    facility_name,
    borough,
    geom AS firehouse_geom,

    ST_Buffer(geom, 2640)::geometry(Polygon, 2263)
        AS buffer_0_5_miles,

    ST_Buffer(geom, 5280)::geometry(Polygon, 2263)
        AS buffer_1_mile,

    ST_Buffer(geom, 10560)::geometry(Polygon, 2263)
        AS buffer_2_miles

FROM core.firehouses;


CREATE INDEX idx_firehouse_distance_buffers_geom
    ON analysis.firehouse_distance_buffers
    USING GIST (firehouse_geom);

ANALYZE analysis.firehouse_distance_buffers;


-- ============================================================
-- 11. Final QC
-- ============================================================

SELECT
    (SELECT COUNT(*)
     FROM core.firehouses) AS firehouses,

    (SELECT COUNT(*)
     FROM analysis.incident_firehouse_accessibility) AS incidents_with_accessibility,

    (SELECT COUNT(*)
     FROM core.incidents
     WHERE geom IS NOT NULL) AS incidents_with_geometry,

    (SELECT COUNT(*)
     FROM analysis.parcel_firehouse_accessibility) AS parcels_with_accessibility,

    (SELECT COUNT(*)
     FROM core.parcels) AS core_parcels;


-- Check that every spatial incident received exactly one
-- nearest firehouse.

SELECT
    COUNT(*) AS incidents,
    COUNT(DISTINCT incident_id) AS unique_incidents
FROM analysis.incident_firehouse_accessibility;


-- Check that every parcel received exactly one nearest
-- firehouse.

SELECT
    COUNT(*) AS parcel_records,
    COUNT(DISTINCT bbl) AS unique_parcels
FROM analysis.parcel_firehouse_accessibility;


-- ============================================================
-- End of analysis/02_firehouse_accessibility.sql
-- ============================================================