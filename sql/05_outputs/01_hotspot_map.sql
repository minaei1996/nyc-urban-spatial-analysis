-- ============================================================
-- 01_hotspot_map.sql
-- NYC Urban Services, Incidents & Spatial Analysis
--
-- Purpose:
--   Prepare a presentation-ready layer of 311 incident
--   hotspots for visualization in QGIS.
--
-- Source:
--   analysis.incident_hotspots
--
-- Spatial unit:
--   Occupied 1,000-ft x 1,000-ft grid cells.
--
-- Density classification:
--   Extreme   = top 1%
--   Very High = top 5%
--   High      = top 10%
--   Other     = remaining cells
--
-- These classifications are empirical and are not official
-- service or incident-density standards.
--
-- CRS:
--   EPSG:2263 - NAD83 / New York Long Island (ftUS)
-- ============================================================


-- ============================================================
-- 1. PRESENTATION-READY HOTSPOT LAYER
-- ============================================================
--
-- The query returns one record per occupied hotspot cell.
--
-- It is intended to be loaded directly into QGIS as a
-- PostgreSQL query layer.
-- ============================================================

WITH thresholds AS (
    SELECT
        PERCENTILE_CONT(0.90)
            WITHIN GROUP (
                ORDER BY incident_count
            ) AS p90,

        PERCENTILE_CONT(0.95)
            WITHIN GROUP (
                ORDER BY incident_count
            ) AS p95,

        PERCENTILE_CONT(0.99)
            WITHIN GROUP (
                ORDER BY incident_count
            ) AS p99

    FROM analysis.incident_hotspots
)

SELECT
    h.hotspot_id,

    h.incident_count,

    h.unique_incident_count,

    ROUND(
        (
            h.incident_count::NUMERIC
            * 27.8784
        ),
        2
    ) AS annual_incidents_per_square_mile,

    CASE
        WHEN h.incident_count >= t.p99
            THEN 'Extreme'

        WHEN h.incident_count >= t.p95
            THEN 'Very High'

        WHEN h.incident_count >= t.p90
            THEN 'High'

        ELSE 'Other'
    END AS density_class,

    h.geom

FROM analysis.incident_hotspots h

CROSS JOIN thresholds t

ORDER BY
    h.incident_count DESC;