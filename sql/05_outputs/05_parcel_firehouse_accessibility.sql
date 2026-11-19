-- ============================================================
-- 05_parcel_firehouse_accessibility.sql
-- NYC Urban Services, Incidents & Spatial Analysis
--
-- Purpose:
--   Prepare a presentation-ready parcel layer showing the
--   geographic distance from each NYC parcel to its nearest
--   FDNY firehouse.
--
-- Source:
--   analysis.parcel_firehouse_accessibility
--
-- Spatial unit:
--   NYC tax parcels identified by BBL.
--
-- Distance:
--   Straight-line geographic distance to the nearest
--   firehouse.
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
    bbl,
    borough,
    address,

    land_use,
    building_class,

    lot_area,
    building_area,
    units_res,
    units_total,

    firehouse_id,
    facility_name,
    firehouse_borough,

    ROUND(
        distance_miles::NUMERIC,
        3
    ) AS distance_to_firehouse_miles,

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
    END AS firehouse_distance_class,

    geom

FROM analysis.parcel_firehouse_accessibility

ORDER BY
    distance_miles DESC;