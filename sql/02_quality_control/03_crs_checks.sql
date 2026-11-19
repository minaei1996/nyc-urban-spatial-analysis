-- ============================================================
-- 03 - CRS Assumption Checks
-- ============================================================


-- FDNY:
-- Latitude/longitude are geographic coordinates.
-- Expected source CRS: EPSG:4326.


SELECT
    MIN(latitude) AS min_lat,
    MAX(latitude) AS max_lat,
    MIN(longitude) AS min_lon,
    MAX(longitude) AS max_lon
FROM raw.fdny_firehouses;


-- NYC 311:
-- Latitude/longitude are expected to be EPSG:4326.
-- X/Y are expected to represent NYC State Plane coordinates.
-- We verify their numerical ranges.

SELECT
    MIN(x_coordinate_state_plane) AS min_x,
    MAX(x_coordinate_state_plane) AS max_x,
    MIN(y_coordinate_state_plane) AS min_y,
    MAX(y_coordinate_state_plane) AS max_y
FROM raw.nyc_311;


-- Mesonet:
-- Latitude/longitude are expected to be EPSG:4326.

SELECT
    MIN(latitude) AS min_lat,
    MAX(latitude) AS max_lat,
    MIN(longitude) AS min_lon,
    MAX(longitude) AS max_lon
FROM raw.mesonet;


-- Rite Aid:
-- Geometry is encoded as EWKB.
-- The EWKB prefix indicates that the source geometry
-- carries SRID information.
--
-- We will verify the actual SRID during core conversion.