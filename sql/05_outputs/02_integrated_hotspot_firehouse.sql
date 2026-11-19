-- ============================================================
-- 02_integrated_hotspot_firehouse.sql
-- NYC Urban Services, Incidents & Spatial Analysis
--
-- Purpose:
--   Prepare a presentation-ready layer integrating 311
--   incident density with geographic distance to the
--   nearest FDNY firehouse.
--
-- Source:
--   analysis.integrated_hotspot_profiles
--
-- Spatial unit:
--   Occupied 1,000-ft x 1,000-ft incident hotspot cells.
--
-- Density classification:
--   Extreme   = top 1%
--   Very High = top 5%
--   High      = top 10%
--   Other     = remaining cells
--
-- Distance:
--   Straight-line geographic distance from each hotspot
--   centroid to its nearest firehouse.
--
-- Important:
--   Distance represents geographic proximity only.
--   It does not represent emergency response time,
--   operational coverage, or service quality.
--
-- CRS:
--   EPSG:2263 - NAD83 / New York Long Island (ftUS)
-- ============================================================

SELECT
    hotspot_id,
    incident_count,
    unique_incident_count,
    density_class,

    ROUND(
        annual_incidents_per_square_mile::NUMERIC,
        2
    ) AS annual_incidents_per_square_mile,

    firehouse_id,
    facility_name,
    firehouse_address,
    firehouse_borough,

    ROUND(
        distance_miles::NUMERIC,
        3
    ) AS distance_to_firehouse_miles,

    CASE
        WHEN distance_miles <= 0.25 THEN '0-0.25 mi'
        WHEN distance_miles <= 0.50 THEN '0.25-0.50 mi'
        WHEN distance_miles <= 1.00 THEN '0.50-1.00 mi'
        WHEN distance_miles <= 2.00 THEN '1.00-2.00 mi'
        ELSE '>2.00 mi'
    END AS firehouse_distance_class,

    geom

FROM analysis.integrated_hotspot_profiles

ORDER BY
    incident_count DESC;
