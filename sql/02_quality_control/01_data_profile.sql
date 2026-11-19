-- ============================================================
-- NYC Urban Services & Spatial Analysis
-- Raw Data Quality Control
-- 01 - General Data Profile
-- ============================================================


-- ------------------------------------------------------------
-- 1. Row counts
-- ------------------------------------------------------------

SELECT 'raw.fdny_firehouses' AS table_name,
       COUNT(*) AS row_count
FROM raw.fdny_firehouses

UNION ALL

SELECT 'raw.nyc_311',
       COUNT(*)
FROM raw.nyc_311

UNION ALL

SELECT 'raw.mesonet',
       COUNT(*)
FROM raw.mesonet

UNION ALL

SELECT 'raw.rite_aid',
       COUNT(*)
FROM raw.rite_aid

UNION ALL

SELECT 'raw.fire_odm',
       COUNT(*)
FROM raw.fire_odm;


-- ------------------------------------------------------------
-- 2. FDNY firehouses - NULL checks
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE facility_name IS NULL) AS missing_name,
    COUNT(*) FILTER (WHERE facility_address IS NULL) AS missing_address,
    COUNT(*) FILTER (WHERE borough IS NULL) AS missing_borough,
    COUNT(*) FILTER (WHERE latitude IS NULL) AS missing_latitude,
    COUNT(*) FILTER (WHERE longitude IS NULL) AS missing_longitude,
    COUNT(*) FILTER (WHERE bbl IS NULL) AS missing_bbl,
    COUNT(*) FILTER (WHERE bin IS NULL) AS missing_bin
FROM raw.fdny_firehouses;


-- ------------------------------------------------------------
-- 3. FDNY coordinate ranges
-- ------------------------------------------------------------

SELECT
    MIN(latitude)  AS min_latitude,
    MAX(latitude)  AS max_latitude,
    MIN(longitude) AS min_longitude,
    MAX(longitude) AS max_longitude
FROM raw.fdny_firehouses;


-- ------------------------------------------------------------
-- 4. FDNY duplicate checks
-- ------------------------------------------------------------

SELECT
    facility_name,
    COUNT(*) AS occurrences
FROM raw.fdny_firehouses
GROUP BY facility_name
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- ------------------------------------------------------------
-- 5. FDNY borough distribution
-- ------------------------------------------------------------

SELECT
    borough,
    COUNT(*) AS firehouse_count
FROM raw.fdny_firehouses
GROUP BY borough
ORDER BY firehouse_count DESC;


-- ------------------------------------------------------------
-- 6. NYC 311 - basic profile
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE latitude IS NOT NULL) AS rows_with_latitude,
    COUNT(*) FILTER (WHERE longitude IS NOT NULL) AS rows_with_longitude,
    COUNT(*) FILTER (WHERE x_coordinate_state_plane IS NOT NULL) AS rows_with_x,
    COUNT(*) FILTER (WHERE y_coordinate_state_plane IS NOT NULL) AS rows_with_y,
    COUNT(*) FILTER (WHERE created_date IS NULL) AS missing_created_date,
    COUNT(*) FILTER (WHERE complaint_type IS NULL) AS missing_complaint_type,
    COUNT(*) FILTER (WHERE borough IS NULL) AS missing_borough,
    COUNT(*) FILTER (WHERE bbl IS NULL) AS missing_bbl
FROM raw.nyc_311;


-- ------------------------------------------------------------
-- 7. NYC 311 coordinate ranges
-- ------------------------------------------------------------

SELECT
    MIN(latitude) AS min_latitude,
    MAX(latitude) AS max_latitude,
    MIN(longitude) AS min_longitude,
    MAX(longitude) AS max_longitude,
    MIN(x_coordinate_state_plane) AS min_x,
    MAX(x_coordinate_state_plane) AS max_x,
    MIN(y_coordinate_state_plane) AS min_y,
    MAX(y_coordinate_state_plane) AS max_y
FROM raw.nyc_311;


-- ------------------------------------------------------------
-- 8. NYC 311 complaint types
-- ------------------------------------------------------------

SELECT
    complaint_type,
    COUNT(*) AS incident_count
FROM raw.nyc_311
GROUP BY complaint_type
ORDER BY incident_count DESC
LIMIT 50;


-- ------------------------------------------------------------
-- 9. NYC 311 agencies
-- ------------------------------------------------------------

SELECT
    agency,
    COUNT(*) AS incident_count
FROM raw.nyc_311
GROUP BY agency
ORDER BY incident_count DESC;


-- ------------------------------------------------------------
-- 10. NYC 311 borough distribution
-- ------------------------------------------------------------

SELECT
    borough,
    COUNT(*) AS incident_count
FROM raw.nyc_311
GROUP BY borough
ORDER BY incident_count DESC;


-- ------------------------------------------------------------
-- 11. NYC 311 created-date samples
-- ------------------------------------------------------------

SELECT
    created_date,
    COUNT(*) AS occurrences
FROM raw.nyc_311
GROUP BY created_date
ORDER BY created_date
LIMIT 20;


-- ------------------------------------------------------------
-- 12. NYC 311 duplicate Unique Keys
-- ------------------------------------------------------------

SELECT
    unique_key,
    COUNT(*) AS occurrences
FROM raw.nyc_311
GROUP BY unique_key
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 50;


-- ------------------------------------------------------------
-- 13. Mesonet profile
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT station) AS station_count,
    MIN(time_end) AS first_timestamp,
    MAX(time_end) AS last_timestamp,
    COUNT(*) FILTER (WHERE temp_2m_avg_c IS NULL) AS missing_temperature,
    COUNT(*) FILTER (WHERE latitude IS NULL) AS missing_latitude,
    COUNT(*) FILTER (WHERE longitude IS NULL) AS missing_longitude
FROM raw.mesonet;


-- ------------------------------------------------------------
-- 14. Mesonet station distribution
-- ------------------------------------------------------------

SELECT
    station,
    COUNT(*) AS observations,
    MIN(latitude) AS latitude,
    MIN(longitude) AS longitude
FROM raw.mesonet
GROUP BY station
ORDER BY station;


-- ------------------------------------------------------------
-- 15. Rite Aid profile
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE geometry_wkb IS NULL) AS missing_geometry,
    COUNT(*) FILTER (WHERE pharm_geometry_wkb IS NULL) AS missing_pharmacy_geometry,
    COUNT(DISTINCT building_id) AS unique_buildings,
    COUNT(DISTINCT pharm_id) AS unique_pharmacies,
    COUNT(DISTINCT name) AS unique_names
FROM raw.rite_aid;


-- ------------------------------------------------------------
-- 16. Fire ODM profile
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT start_vid) AS unique_start_vertices,
    COUNT(DISTINCT end_vid) AS unique_end_vertices,
    MIN(agg_cost) AS minimum_cost,
    MAX(agg_cost) AS maximum_cost,
    AVG(agg_cost) AS average_cost
FROM raw.fire_odm;


-- ------------------------------------------------------------
-- 17. Fire ODM start vertices
-- ------------------------------------------------------------

SELECT
    start_vid,
    COUNT(*) AS destination_count
FROM raw.fire_odm
GROUP BY start_vid
ORDER BY start_vid;


-- ------------------------------------------------------------
-- 18. Fire ODM possible duplicate OD pairs
-- ------------------------------------------------------------

SELECT
    start_vid,
    end_vid,
    COUNT(*) AS occurrences
FROM raw.fire_odm
GROUP BY start_vid, end_vid
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;