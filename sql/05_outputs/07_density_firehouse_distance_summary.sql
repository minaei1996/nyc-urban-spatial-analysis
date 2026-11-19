-- ============================================================
-- 07_density_firehouse_distance_summary.sql
-- NYC Urban Services, Incidents & Spatial Analysis
--
-- Purpose:
--   Produce a compact statistical summary comparing 311
--   incident density classes with geographic distance to
--   the nearest FDNY firehouse.
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
--   to its nearest firehouse.
--
-- Important:
--   Distance represents geographic proximity only.
--   It does not represent emergency response time,
--   operational coverage, travel time, or service quality.
--
-- CRS:
--   EPSG:2263 - NAD83 / New York Long Island (ftUS)
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
    ) AS p90_firehouse_distance_miles,

    COUNT(*) FILTER (
        WHERE distance_miles > 1.00
    ) AS hotspots_over_1_mile,

    ROUND(
        (
            COUNT(*) FILTER (
                WHERE distance_miles <= 1.00
            )::NUMERIC
            / COUNT(*) * 100
        ),
        2
    ) AS percent_within_1_mile

FROM analysis.integrated_hotspot_profiles

GROUP BY
    density_class

ORDER BY
    CASE density_class
        WHEN 'Extreme' THEN 1
        WHEN 'Very High' THEN 2
        WHEN 'High' THEN 3
        WHEN 'Other' THEN 4
        ELSE 5
    END;