-- ============================================================
-- 03_parcel_incident_profiles.sql
-- NYC Urban Services, Incidents & Spatial Analysis
--
-- Purpose:
--   Prepare a presentation-ready parcel layer showing
--   311 incident activity associated with NYC tax parcels.
--
-- Source:
--   analysis.parcel_incident_profiles
--
-- Spatial unit:
--   NYC tax parcels identified by BBL.
--
-- Incident linkage:
--   Incidents are linked to parcels primarily through BBL.
--   Additional spatial assignment was performed for
--   geometry-valid incidents without a BBL.
--
-- Important:
--   Incident counts describe recorded 311 activity associated
--   with a parcel. They should not be interpreted as a direct
--   measure of property condition, risk, or service quality.
--
-- CRS:
--   EPSG:2263 - NAD83 / New York Long Island (ftUS)
-- ============================================================

SELECT
    bbl,
    borough,
    block,
    lot,
    address,

    land_use,
    building_class,

    lot_area,
    building_area,
    residential_area,
    commercial_area,
    office_area,
    retail_area,

    num_buildings,
    num_floors,
    units_res,
    units_total,
    year_built,

    incident_count,
    complaint_type_count,
    agency_count,

    first_incident_at,
    last_incident_at,

    CASE
        WHEN incident_count = 0 THEN 'No incidents'
        WHEN incident_count <= 5 THEN '1-5'
        WHEN incident_count <= 20 THEN '6-20'
        WHEN incident_count <= 100 THEN '21-100'
        WHEN incident_count <= 500 THEN '101-500'
        ELSE '>500'
    END AS incident_count_class,

    geom

FROM analysis.parcel_incident_profiles

ORDER BY
    incident_count DESC;
