-- ============================================================
-- Analysis: NYC 311 Incident Hotspots
-- Source: core.incidents
--
-- Purpose:
--   Identify areas with high concentrations of NYC 311
--   incidents using a regular 1,000 ft x 1,000 ft spatial grid.
--
-- Analytical approach:
--   1. Aggregate spatially valid incidents into grid cells.
--   2. Calculate incident density per square mile.
--   3. Classify cells using empirical percentile thresholds.
--   4. Identify dominant complaint types within each cell.
--   5. Produce borough-level summaries.
--   6. Produce a dedicated top-1% hotspot layer for QGIS.
--
-- Hotspot classification:
--   Top 10% -> High
--   Top 5%  -> Very High
--   Top 1%  -> Extreme
--   Remaining cells -> Other
--
-- Notes:
--   - Only incidents with valid geometry are included.
--   - All original 311 records remain available in
--     core.incidents.
--   - A grid cell is an analytical unit, not a claim that the
--     entire area represented by the cell is homogeneous.
--   - Percentile thresholds are based on occupied grid cells.
--   - These results describe spatial concentration and do not
--     establish statistical significance or causation.
--   - Incident counts are not normalized for population,
--     properties, or other exposure variables.
-- ============================================================


-- ============================================================
-- 1. Incident density by 1,000 ft grid
-- ============================================================

DROP TABLE IF EXISTS analysis.incident_hotspots;


CREATE TABLE analysis.incident_hotspots AS

WITH incident_grid AS (
    SELECT
        i.incident_id,
        ST_SnapToGrid(
            i.geom,
            1000.0,
            1000.0
        ) AS grid_origin
    FROM core.incidents AS i
    WHERE i.geom IS NOT NULL
),

grid_counts AS (
    SELECT
        grid_origin,
        COUNT(*) AS incident_count
    FROM incident_grid
    GROUP BY grid_origin
),

percentiles AS (
    SELECT
        PERCENTILE_CONT(0.90)
            WITHIN GROUP (ORDER BY incident_count) AS p90,
        PERCENTILE_CONT(0.95)
            WITHIN GROUP (ORDER BY incident_count) AS p95,
        PERCENTILE_CONT(0.99)
            WITHIN GROUP (ORDER BY incident_count) AS p99
    FROM grid_counts
)

SELECT
    ROW_NUMBER() OVER (
        ORDER BY
            g.incident_count DESC,
            ST_Y(g.grid_origin),
            ST_X(g.grid_origin)
    )::BIGINT AS hotspot_id,

    g.incident_count,

    ROUND(
        g.incident_count::NUMERIC
        * 27878.4
        / 1000000.0,
        2
    ) AS incidents_per_square_mile,

    CASE
        WHEN g.incident_count >= p.p99 THEN 'Extreme'
        WHEN g.incident_count >= p.p95 THEN 'Very High'
        WHEN g.incident_count >= p.p90 THEN 'High'
        ELSE 'Other'
    END AS density_class,

    ST_SetSRID(
        ST_MakeEnvelope(
            ST_X(g.grid_origin),
            ST_Y(g.grid_origin),
            ST_X(g.grid_origin) + 1000.0,
            ST_Y(g.grid_origin) + 1000.0,
            2263
        ),
        2263
    )::geometry(Polygon, 2263) AS geom

FROM grid_counts AS g
CROSS JOIN percentiles AS p;


ALTER TABLE analysis.incident_hotspots
ADD CONSTRAINT incident_hotspots_pk
PRIMARY KEY (hotspot_id);


COMMENT ON TABLE analysis.incident_hotspots IS
'NYC 311 incident density aggregated into 1,000 ft x 1,000 ft analytical grid cells. Density classes are based on the empirical distribution of occupied grid cells.';


COMMENT ON COLUMN analysis.incident_hotspots.incident_count IS
'Number of spatially valid 311 incidents assigned to the grid cell.';


COMMENT ON COLUMN analysis.incident_hotspots.incidents_per_square_mile IS
'Incident count scaled to the equivalent number of incidents per square mile.';


COMMENT ON COLUMN analysis.incident_hotspots.density_class IS
'Empirical density class: Extreme (top 1%), Very High (top 5%), High (top 10%), or Other.';


COMMENT ON COLUMN analysis.incident_hotspots.geom IS
'1,000 ft x 1,000 ft analytical grid cell in EPSG:2263.';


CREATE INDEX incident_hotspots_geom_gix
ON analysis.incident_hotspots
USING GIST (geom);


CREATE INDEX incident_hotspots_count_idx
ON analysis.incident_hotspots (incident_count);


CREATE INDEX incident_hotspots_density_class_idx
ON analysis.incident_hotspots (density_class);


ANALYZE analysis.incident_hotspots;


-- ============================================================
-- 2. Overall grid statistics
-- ============================================================

SELECT
    COUNT(*) AS grid_cells,
    SUM(incident_count) AS incidents_in_grid,
    MIN(incident_count) AS minimum_incidents_per_cell,
    ROUND(AVG(incident_count), 2) AS mean_incidents_per_cell,

    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY incident_count) AS median_incidents_per_cell,

    PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY incident_count) AS p90_incidents_per_cell,

    PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY incident_count) AS p95_incidents_per_cell,

    PERCENTILE_CONT(0.99)
        WITHIN GROUP (ORDER BY incident_count) AS p99_incidents_per_cell,

    MAX(incident_count) AS maximum_incidents_per_cell
FROM analysis.incident_hotspots;


-- ============================================================
-- 3. Density-class distribution
-- ============================================================

SELECT
    density_class,
    COUNT(*) AS grid_cell_count,
    SUM(incident_count) AS incident_count,
    ROUND(
        100.0 * SUM(incident_count)
        / SUM(SUM(incident_count)) OVER (),
        2
    ) AS percent_of_incidents
FROM analysis.incident_hotspots
GROUP BY density_class
ORDER BY
    CASE density_class
        WHEN 'Extreme' THEN 1
        WHEN 'Very High' THEN 2
        WHEN 'High' THEN 3
        WHEN 'Other' THEN 4
    END;


-- ============================================================
-- 4. Top 20 grid cells
-- ============================================================

SELECT
    hotspot_id,
    incident_count,
    incidents_per_square_mile,
    density_class,
    ST_X(ST_Centroid(geom)) AS centroid_x,
    ST_Y(ST_Centroid(geom)) AS centroid_y
FROM analysis.incident_hotspots
ORDER BY incident_count DESC
LIMIT 20