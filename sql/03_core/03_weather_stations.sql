-- ============================================================
-- Core: NYS Mesonet Weather Observations
-- Source: raw.mesonet
--
-- Purpose:
--   Convert raw NYS Mesonet observations into a standardized
--   spatial and temporal table for weather/incident analysis.
--
-- Spatial reference systems:
--   EPSG:4326  - WGS 84 geographic coordinates
--   EPSG:2263  - NAD83 / New York Long Island (ftUS)
--
-- Notes:
--   - Each row represents one station observation at one time.
--   - Source temperature NULLs are preserved.
--   - No missing-value imputation is performed.
--   - The source dataset covers 2023-07-23 to 2023-07-24,
--     whereas the NYC 311 dataset covers 2021.
--   - Therefore, this table should not be directly joined to
--     the 2021 incident data as if the periods were aligned.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Recreate table
-- ------------------------------------------------------------

DROP TABLE IF EXISTS core.weather_stations;


CREATE TABLE core.weather_stations (
    weather_id                    BIGINT PRIMARY KEY,

    station                       TEXT NOT NULL,
    observed_at                   TIMESTAMPTZ NOT NULL,

    latitude                      DOUBLE PRECISION NOT NULL,
    longitude                     DOUBLE PRECISION NOT NULL,
    elevation_m                   DOUBLE PRECISION,

    temp_2m_max_c                 DOUBLE PRECISION,
    temp_2m_min_c                 DOUBLE PRECISION,
    temp_2m_avg_c                 DOUBLE PRECISION,

    apparent_temperature_max_c    DOUBLE PRECISION,
    apparent_temperature_min_c    DOUBLE PRECISION,
    apparent_temperature_avg_c    DOUBLE PRECISION,

    geom_4326                     geometry(Point, 4326),
    geom                         geometry(Point, 2263)
);


-- ------------------------------------------------------------
-- 2. Populate core table
-- ------------------------------------------------------------

INSERT INTO core.weather_stations (
    weather_id,
    station,
    observed_at,

    latitude,
    longitude,
    elevation_m,

    temp_2m_max_c,
    temp_2m_min_c,
    temp_2m_avg_c,

    apparent_temperature_max_c,
    apparent_temperature_min_c,
    apparent_temperature_avg_c,

    geom_4326,
    geom
)

SELECT
    ROW_NUMBER() OVER (
        ORDER BY station, time_end
    )::BIGINT AS weather_id,

    station,

    time_end::TIMESTAMPTZ AS observed_at,

    latitude,
    longitude,
    elevation_m,

    temp_2m_max_c,
    temp_2m_min_c,
    temp_2m_avg_c,

    apparent_temperature_max_c,
    apparent_temperature_min_c,
    apparent_temperature_avg_c,

    ST_SetSRID(
        ST_MakePoint(longitude, latitude),
        4326
    )::geometry(Point, 4326) AS geom_4326,

    ST_Transform(
        ST_SetSRID(
            ST_MakePoint(longitude, latitude),
            4326
        ),
        2263
    )::geometry(Point, 2263) AS geom

FROM raw.mesonet;


-- ------------------------------------------------------------
-- 3. Documentation
-- ------------------------------------------------------------

COMMENT ON TABLE core.weather_stations IS
'Standardized NYS Mesonet weather observations with spatial and temporal attributes. Each row represents one station observation at one timestamp.';

COMMENT ON COLUMN core.weather_stations.weather_id IS
'Project-generated identifier for an individual station observation.';

COMMENT ON COLUMN core.weather_stations.station IS
'NYS Mesonet station identifier.';

COMMENT ON COLUMN core.weather_stations.observed_at IS
'Observation timestamp from the source dataset.';

COMMENT ON COLUMN core.weather_stations.geom_4326 IS
'Weather station location in WGS 84 geographic coordinates (EPSG:4326).';

COMMENT ON COLUMN core.weather_stations.geom IS
'Weather station location projected to NAD83 / New York Long Island ftUS (EPSG:2263).';


-- ------------------------------------------------------------
-- 4. Spatial indexes
-- ------------------------------------------------------------

CREATE INDEX weather_stations_geom_4326_gix
ON core.weather_stations
USING GIST (geom_4326);

CREATE INDEX weather_stations_geom_gix
ON core.weather_stations
USING GIST (geom);


-- ------------------------------------------------------------
-- 5. Analytical indexes
-- ------------------------------------------------------------

CREATE INDEX weather_stations_station_idx
ON core.weather_stations (station);

CREATE INDEX weather_stations_observed_at_idx
ON core.weather_stations (observed_at);

CREATE INDEX weather_stations_station_time_idx
ON core.weather_stations (station, observed_at);


-- ------------------------------------------------------------
-- 6. Update table statistics
-- ------------------------------------------------------------

ANALYZE core.weather_stations;


-- ============================================================
-- 7. Quality-control checks
-- ============================================================


-- 7.1 Row count
SELECT
    COUNT(*) AS row_count
FROM core.weather_stations;


-- 7.2 Station count
SELECT
    COUNT(DISTINCT station) AS station_count
FROM core.weather_stations;


-- 7.3 Observations per station
SELECT
    station,
    COUNT(*) AS observation_count,
    MIN(observed_at) AS first_observation,
    MAX(observed_at) AS last_observation
FROM core.weather_stations
GROUP BY station
ORDER BY station;


-- 7.4 Geometry type and SRID
SELECT
    ST_GeometryType(geom) AS geometry_type,
    ST_SRID(geom) AS srid,
    COUNT(*) AS feature_count
FROM core.weather_stations
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
FROM core.weather_stations;


-- 7.6 Temporal range
SELECT
    MIN(observed_at) AS earliest_observation,
    MAX(observed_at) AS latest_observation
FROM core.weather_stations;


-- 7.7 Coordinate consistency
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
FROM core.weather_stations;


-- 7.8 Missing weather measurements
SELECT
    COUNT(*) AS total_observations,

    COUNT(*) FILTER (
        WHERE temp_2m_max_c IS NULL
    ) AS missing_temp_max,

    COUNT(*) FILTER (
        WHERE temp_2m_min_c IS NULL
    ) AS missing_temp_min,

    COUNT(*) FILTER (
        WHERE temp_2m_avg_c IS NULL
    ) AS missing_temp_avg,

    COUNT(*) FILTER (
        WHERE apparent_temperature_max_c IS NULL
    ) AS missing_apparent_max,

    COUNT(*) FILTER (
        WHERE apparent_temperature_min_c IS NULL
    ) AS missing_apparent_min,

    COUNT(*) FILTER (
        WHERE apparent_temperature_avg_c IS NULL
    ) AS missing_apparent_avg

FROM core.weather_stations;


-- 7.9 Station locations
SELECT
    station,
    latitude,
    longitude,
    elevation_m
FROM core.weather_stations
GROUP BY
    station,
    latitude,
    longitude,
    elevation_m
ORDER BY station;


-- 7.10 Spatial extent
SELECT
    ST_XMin(extent) AS min_x,
    ST_YMin(extent) AS min_y,
    ST_XMax(extent) AS max_x,
    ST_YMax(extent) AS max_y
FROM (
    SELECT ST_Extent(geom) AS extent
    FROM core.weather_stations
) AS e;


-- 7.11 Check for duplicate station/timestamp observations
SELECT
    station,
    observed_at,
    COUNT(*) AS duplicate_count
FROM core.weather_stations
GROUP BY
    station,
    observed_at
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- 7.12 NYC stations
SELECT
    station,
    COUNT(*) AS observation_count
FROM core.weather_stations
WHERE station IN (
    'BKLN',
    'BRON',
    'MANH',
    'QUEE',
    'STAT'
)
GROUP BY station
ORDER BY station;