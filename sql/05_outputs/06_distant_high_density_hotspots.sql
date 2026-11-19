-- ============================================================
-- 06_distant_high_density_hotspots.sql
-- NYC Urban Services, Incidents & Spatial Analysis
--
-- Purpose:
--   Prepare a presentation-ready layer highlighting
--   high-density 311 incident hotspots that are geographically
--   distant from their nearest FDNY firehouse.
--
-- Source:
--   analysis.distant_high_density_hotspots
--
-- Selection:
--   High, Very High, and Extreme incident-density hotspots
--   located more than 1 mile from their nearest firehouse.
--
-- Density classification:
--   Extreme   = top 1%
--   Very High = top 5%
--   High      = top 10%
--
-- Important:
--   These classifications are empirical and are not official
--   service or incident-density standards.
--
--   Firehouse distance represents geographic proximity only.
--   It does not represent emergency response time,
--   operational coverage, travel time, or service quality.
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
    firehouse_borough,

    ROUND(
        distance_miles::NUMERIC,
        3
    ) AS distance_to_firehouse_miles,

    CASE
        WHEN distance_miles <= 1.00
            THEN '0-1 mi'
        WHEN distance_miles <= 2.00
            THEN '1-2 mi'
        ELSE '>2 mi'
    END AS firehouse_distance_class,

    geom

FROM analysis.distant_high_density_hotspots

ORDER BY
    distance_miles DESC,
    incident_count DESC;