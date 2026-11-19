-- ============================================================
-- 04_high_incident_parcels_rite_aid_distance.sql
-- NYC Urban Services, Incidents & Spatial Analysis
--
-- Purpose:
--   Prepare a presentation-ready layer highlighting parcels
--   with relatively high recorded 311 activity that are also
--   geographically distant from the recorded Rite Aid locations.
--
-- Source:
--   analysis.parcel_pharmacy_accessibility
--
-- Spatial unit:
--   NYC tax parcels identified by BBL.
--
-- Selection:
--   Parcels in the top 5% of incident-active parcels by
--   recorded 311 incident count.
--
-- Important:
--   This analysis describes geographic proximity to the
--   recorded Rite Aid locations in the dataset.
--   It does not measure healthcare accessibility,
--   pharmacy utilization, service availability, or need.
--
-- CRS:
--   EPSG:2263 - NAD83 / New York Long Island (ftUS)
-- ============================================================

WITH threshold AS (
    SELECT
        PERCENTILE_CONT(0.95)
            WITHIN GROUP (
                ORDER BY incident_count
            ) AS p95_incident_count
    FROM analysis.parcel_pharmacy_accessibility
    WHERE incident_count > 0
)

SELECT
    p.bbl,
    p.borough,
    p.address,

    p.land_use,
    p.building_class,

    p.incident_count,

    p.pharmacy_id,
    p.pharm_id,
    p.pharmacy_name,

    ROUND(
        p.nearest_pharmacy_distance_miles::NUMERIC,
        3
    ) AS nearest_pharmacy_distance_miles,

    CASE
        WHEN p.nearest_pharmacy_distance_miles <= 0.25
            THEN '0-0.25 mi'
        WHEN p.nearest_pharmacy_distance_miles <= 0.50
            THEN '0.25-0.50 mi'
        WHEN p.nearest_pharmacy_distance_miles <= 1.00
            THEN '0.50-1.00 mi'
        WHEN p.nearest_pharmacy_distance_miles <= 2.00
            THEN '1.00-2.00 mi'
        ELSE '>2.00 mi'
    END AS pharmacy_distance_class,

    p.parcel_geom AS geom

FROM analysis.parcel_pharmacy_accessibility p
CROSS JOIN threshold t

WHERE
    p.incident_count > 0
    AND p.incident_count >= t.p95_incident_count

ORDER BY
    p.nearest_pharmacy_distance_miles DESC,
    p.incident_count DESC;
