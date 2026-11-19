-- ============================================================
-- Core: NYC 311 Incidents
-- Source: raw.nyc_311
--
-- Purpose:
--   Convert the raw NYC 311 dataset into a standardized
--   analytical table with parsed timestamps and PostGIS
--   geometries.
--
-- Spatial reference systems:
--   EPSG:4326  - geographic coordinates (source/reference)
--   EPSG:2263  - NAD83 / New York Long Island (ftUS)
--
-- Notes:
--   - Raw source values are preserved in raw.nyc_311.
--   - Records with missing coordinates are retained.
--   - Clearly invalid coordinates are represented by NULL geom.
--   - The known invalid coordinate in the source is identified
--     through coordinate validity checks rather than deleted.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Recreate table
-- ------------------------------------------------------------

DROP TABLE IF EXISTS core.incidents;


CREATE TABLE core.incidents (
    incident_id                    BIGINT PRIMARY KEY,

    created_at                     TIMESTAMPTZ,
    closed_at                      TIMESTAMPTZ,

    agency                         TEXT,
    agency_name                    TEXT,

    complaint_type                 TEXT,
    descriptor                     TEXT,
    location_type                  TEXT,

    incident_zip                   TEXT,
    incident_address               TEXT,
    street_name                    TEXT,
    cross_street_1                 TEXT,
    cross_street_2                 TEXT,
    intersection_street_1          TEXT,
    intersection_street_2          TEXT,
    address_type                   TEXT,
    city                           TEXT,

    landmark                       TEXT,

    facility_type                  TEXT,
    status                         TEXT,
    due_at                         TIMESTAMPTZ,

    resolution_description         TEXT,
    resolution_action_updated_at   TIMESTAMPTZ,

    community_board                TEXT,
    bbl                            DOUBLE PRECISION,
    borough                        TEXT,

    x_coordinate_state_plane       DOUBLE PRECISION,
    y_coordinate_state_plane       DOUBLE PRECISION,

    open_data_channel_type         TEXT,

    park_facility_name             TEXT,
    park_borough                   TEXT,

    vehicle_type                   TEXT,
    taxi_company_borough           TEXT,
    taxi_pick_up_location          TEXT,

    bridge_highway_name            TEXT,
    bridge_highway_direction       TEXT,
    road_ramp                      TEXT,
    bridge_highway_segment         TEXT,

    latitude                       DOUBLE PRECISION,
    longitude                      DOUBLE PRECISION,

    geom_4326                      geometry(Point, 4326),
    geom                           geometry(Point, 2263)
);


-- ------------------------------------------------------------
-- 2. Populate core table
-- ------------------------------------------------------------

INSERT INTO core.incidents (
    incident_id,

    created_at,
    closed_at,

    agency,
    agency_name,

    complaint_type,
    descriptor,
    location_type,

    incident_zip,
    incident_address,
    street_name,
    cross_street_1,
    cross_street_2,
    intersection_street_1,
    intersection_street_2,
    address_type,
    city,

    landmark,

    facility_type,
    status,
    due_at,

    resolution_description,
    resolution_action_updated_at,

    community_board,
    bbl,
    borough,

    x_coordinate_state_plane,
    y_coordinate_state_plane,

    open_data_channel_type,

    park_facility_name,
    park_borough,

    vehicle_type,
    taxi_company_borough,
    taxi_pick_up_location,

    bridge_highway_name,
    bridge_highway_direction,
    road_ramp,
    bridge_highway_segment,

    latitude,
    longitude,

    geom_4326,
    geom
)

SELECT
    unique_key AS incident_id,

    CASE
        WHEN created_date IS NOT NULL
        THEN created_date::TIMESTAMPTZ
    END AS created_at,

    CASE
        WHEN closed_date IS NOT NULL
        THEN closed_date::TIMESTAMPTZ
    END AS closed_at,

    agency,
    agency_name,

    complaint_type,
    descriptor,
    location_type,

    incident_zip,
    incident_address,
    street_name,
    cross_street_1,
    cross_street_2,
    intersection_street_1,
    intersection_street_2,
    address_type,
    city,

    landmark,

    facility_type,
    status,

    CASE
        WHEN due_date IS NOT NULL
        THEN due_date::TIMESTAMPTZ
    END AS due_at,

    resolution_description,

    CASE
        WHEN resolution_action_updated_date IS NOT NULL
        THEN resolution_action_updated_date::TIMESTAMPTZ
    END AS resolution_action_updated_at,

    community_board,
    bbl,
    borough,

    x_coordinate_state_plane,
    y_coordinate_state_plane,

    open_data_channel_type,

    park_facility_name,
    park_borough,

    vehicle_type,
    taxi_company_borough,
    taxi_pick_up_location,

    bridge_highway_name,
    bridge_highway_direction,
    road_ramp,
    bridge_highway_segment,

    latitude,
    longitude,

    -- Geographic geometry.
    CASE
        WHEN latitude BETWEEN -90 AND 90
         AND longitude BETWEEN -180 AND 180
         AND NOT (
             latitude BETWEEN -0.001 AND 0.001
             AND longitude BETWEEN -0.001 AND 0.001
         )
        THEN ST_SetSRID(
            ST_MakePoint(longitude, latitude),
            4326
        )::geometry(Point, 4326)
        ELSE NULL
    END AS geom_4326,

    -- Projected geometry used for NYC distance/area analysis.
    CASE
        WHEN latitude BETWEEN -90 AND 90
         AND longitude BETWEEN -180 AND 180
         AND NOT (
             latitude BETWEEN -0.001 AND 0.001
             AND longitude BETWEEN -0.001 AND 0.001
         )
        THEN ST_Transform(
            ST_SetSRID(
                ST_MakePoint(longitude, latitude),
                4326
            ),
            2263
        )::geometry(Point, 2263)
        ELSE NULL
    END AS geom

FROM raw.nyc_311;


-- ------------------------------------------------------------
-- 3. Documentation
-- ------------------------------------------------------------

COMMENT ON TABLE core.incidents IS
'Standardized NYC 311 incident records prepared for spatial and temporal analysis.';

COMMENT ON COLUMN core.incidents.incident_id IS
'Unique NYC 311 complaint identifier from the source dataset.';

COMMENT ON COLUMN core.incidents.geom_4326 IS
'Incident point in WGS 84 geographic coordinates (EPSG:4326).';

COMMENT ON COLUMN core.incidents.geom IS
'Incident point projected to NAD83 / New York Long Island ftUS (EPSG:2263), used for spatial analysis.';

COMMENT ON COLUMN core.incidents.latitude IS
'Original latitude value from the NYC 311 source dataset.';

COMMENT ON COLUMN core.incidents.longitude IS
'Original longitude value from the NYC 311 source dataset.';


-- ------------------------------------------------------------
-- 4. Spatial indexes
-- ------------------------------------------------------------

CREATE INDEX incidents_geom_4326_gix
ON core.incidents
USING GIST (geom_4326);

CREATE INDEX incidents_geom_gix
ON core.incidents
USING GIST (geom);


-- ------------------------------------------------------------
-- 5. Analytical indexes
-- ------------------------------------------------------------

CREATE INDEX incidents_created_at_idx
ON core.incidents (created_at);

CREATE INDEX incidents_complaint_type_idx
ON core.incidents (complaint_type);

CREATE INDEX incidents_agency_idx
ON core.incidents (agency);

CREATE INDEX incidents_borough_idx
ON core.incidents (borough);


-- ------------------------------------------------------------
-- 6. Update table statistics
-- ------------------------------------------------------------

ANALYZE core.incidents;


-- ============================================================
-- 7. Quality-control checks
-- ============================================================

-- 7.1 Row count
SELECT
    COUNT(*) AS row_count
FROM core.incidents;


-- 7.2 Unique incident IDs
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT incident_id) AS unique_incident_ids
FROM core.incidents;


-- 7.3 Geometry availability
SELECT
    COUNT(*) AS total_rows,
    COUNT(geom_4326) AS geom_4326_count,
    COUNT(geom) AS geom_2263_count,
    COUNT(*) - COUNT(geom) AS missing_geometry
FROM core.incidents;


-- 7.4 Geometry type and SRID
SELECT
    ST_GeometryType(geom) AS geometry_type,
    ST_SRID(geom) AS srid,
    COUNT(*) AS feature_count
FROM core.incidents
WHERE geom IS NOT NULL
GROUP BY
    ST_GeometryType(geom),
    ST_SRID(geom);


-- 7.5 Geometry validity
SELECT
    COUNT(*) AS total_geometries,
    COUNT(*) FILTER (
        WHERE ST_IsValid(geom)
    ) AS valid_geometries,
    COUNT(*) FILTER (
        WHERE NOT ST_IsValid(geom)
    ) AS invalid_geometries
FROM core.incidents
WHERE geom IS NOT NULL;


-- 7.6 Temporal range
SELECT
    MIN(created_at) AS earliest_incident,
    MAX(created_at) AS latest_incident
FROM core.incidents;


-- 7.7 Coordinate consistency
-- Compare the source geographic coordinates with the
-- coordinates obtained by transforming the projected geometry
-- back to EPSG:4326.

SELECT
    AVG(
        ST_Distance(
            geom_4326::geography,
            ST_Transform(geom, 4326)::geography
        )
    ) AS mean_difference_meters,
    MAX(
        ST_Distance(
            geom_4326::geography,
            ST_Transform(geom, 4326)::geography
        )
    ) AS max_difference_meters
FROM core.incidents
WHERE geom IS NOT NULL;


-- 7.8 Records without usable geometry
SELECT
    incident_id,
    created_at,
    complaint_type,
    borough,
    latitude,
    longitude
FROM core.incidents
WHERE geom IS NULL
ORDER BY incident_id;


-- 7.9 Borough distribution
SELECT
    borough,
    COUNT(*) AS incident_count
FROM core.incidents
GROUP BY borough
ORDER BY incident_count DESC;


-- 7.10 Top complaint types
SELECT
    complaint_type,
    COUNT(*) AS incident_count
FROM core.incidents
GROUP BY complaint_type
ORDER BY incident_count DESC
LIMIT 20;


-- 7.11 Missing coordinate statistics
SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (
        WHERE latitude IS NULL
           OR longitude IS NULL
    ) AS missing_lat_lon,

    COUNT(*) FILTER (
        WHERE geom IS NULL
          AND latitude IS NOT NULL
          AND longitude IS NOT NULL
    ) AS invalid_coordinates
FROM core.incidents;


-- 7.12 Check the known suspicious source coordinate
SELECT
    incident_id,
    created_at,
    complaint_type,
    borough,
    latitude,
    longitude,
    x_coordinate_state_plane,
    y_coordinate_state_plane,
    geom
FROM core.incidents
WHERE latitude BETWEEN -0.001 AND 0.001
   OR longitude BETWEEN -0.001 AND 0.001;


-- 7.13 Spatial extent
SELECT
    ST_XMin(extent) AS min_x,
    ST_YMin(extent) AS min_y,
    ST_XMax(extent) AS max_x,
    ST_YMax(extent) AS max_y
FROM (
    SELECT ST_Extent(geom) AS extent
    FROM core.incidents
    WHERE geom IS NOT NULL
) AS e;