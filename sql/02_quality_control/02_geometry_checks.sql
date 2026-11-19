-- ============================================================
-- 02 - Geometry / Coordinate Quality Checks
-- ============================================================


-- ------------------------------------------------------------
-- 1. FDNY coordinate validity
-- ------------------------------------------------------------

SELECT COUNT(*) AS invalid_coordinates
FROM raw.fdny_firehouses
WHERE latitude IS NOT NULL
  AND longitude IS NOT NULL
  AND (
      latitude NOT BETWEEN -90 AND 90
      OR longitude NOT BETWEEN -180 AND 180
  );


-- ------------------------------------------------------------
-- 2. NYC 311 coordinate validity
-- ------------------------------------------------------------

SELECT COUNT(*) AS invalid_coordinates
FROM raw.nyc_311
WHERE latitude IS NOT NULL
  AND longitude IS NOT NULL
  AND (
      latitude NOT BETWEEN -90 AND 90
      OR longitude NOT BETWEEN -180 AND 180
  );


-- ------------------------------------------------------------
-- 3. NYC 311 latitude/longitude completeness
-- ------------------------------------------------------------

SELECT
    COUNT(*) FILTER (
        WHERE latitude IS NOT NULL
          AND longitude IS NOT NULL
    ) AS complete_coordinates,

    COUNT(*) FILTER (
        WHERE latitude IS NULL
           OR longitude IS NULL
    ) AS incomplete_coordinates
FROM raw.nyc_311;


-- ------------------------------------------------------------
-- 4. NYC 311 State Plane completeness
-- ------------------------------------------------------------

SELECT
    COUNT(*) FILTER (
        WHERE x_coordinate_state_plane IS NOT NULL
          AND y_coordinate_state_plane IS NOT NULL
    ) AS complete_state_plane,

    COUNT(*) FILTER (
        WHERE x_coordinate_state_plane IS NULL
           OR y_coordinate_state_plane IS NULL
    ) AS incomplete_state_plane
FROM raw.nyc_311;


-- ------------------------------------------------------------
-- 5. NYC 311 coordinate consistency
--
-- Transform lat/lon from EPSG:4326 to NYC State Plane
-- EPSG:2263 and compare against source X/Y.
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS comparable_records,

    AVG(
        ST_Distance(
            ST_Transform(
                ST_SetSRID(
                    ST_MakePoint(longitude, latitude),
                    4326
                ),
                2263
            ),
            ST_SetSRID(
                ST_MakePoint(
                    x_coordinate_state_plane,
                    y_coordinate_state_plane
                ),
                2263
            )
        )
    ) AS mean_difference_feet,

    MAX(
        ST_Distance(
            ST_Transform(
                ST_SetSRID(
                    ST_MakePoint(longitude, latitude),
                    4326
                ),
                2263
            ),
            ST_SetSRID(
                ST_MakePoint(
                    x_coordinate_state_plane,
                    y_coordinate_state_plane
                ),
                2263
            )
        )
    ) AS max_difference_feet

FROM raw.nyc_311
WHERE latitude IS NOT NULL
  AND longitude IS NOT NULL
  AND x_coordinate_state_plane IS NOT NULL
  AND y_coordinate_state_plane IS NOT NULL;


-- ------------------------------------------------------------
-- 6. FDNY duplicate coordinates
-- ------------------------------------------------------------

SELECT
    latitude,
    longitude,
    COUNT(*) AS occurrences
FROM raw.fdny_firehouses
GROUP BY latitude, longitude
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- ------------------------------------------------------------
-- 7. Mesonet coordinate validity
-- ------------------------------------------------------------

SELECT COUNT(*) AS invalid_coordinates
FROM raw.mesonet
WHERE latitude IS NOT NULL
  AND longitude IS NOT NULL
  AND (
      latitude NOT BETWEEN -90 AND 90
      OR longitude NOT BETWEEN -180 AND 180
  );


-- ------------------------------------------------------------
-- 8. Mesonet duplicate station/timestamp observations
-- ------------------------------------------------------------

SELECT
    station,
    time_end,
    COUNT(*) AS occurrences
FROM raw.mesonet
GROUP BY station, time_end
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;