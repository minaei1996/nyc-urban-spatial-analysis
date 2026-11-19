/*
    Core Firehouses
    ===============

    Source:
        raw.fdny_firehouses

    Purpose:
        Create a cleaned and standardized FDNY firehouse layer
        for spatial analysis.

    Core-layer principles:
        - Preserve the raw table unchanged.
        - Standardize field names and data types.
        - Create a PostGIS geometry from source coordinates.
        - Use EPSG:2263 for NYC spatial analysis.
        - Add a spatial index for analytical queries.
*/


/* ============================================================
   1. CREATE CORE TABLE
   ============================================================ */

DROP TABLE IF EXISTS core.firehouses;

CREATE TABLE core.firehouses AS

SELECT
    ROW_NUMBER() OVER (
        ORDER BY facility_name, latitude, longitude
    )::INTEGER AS firehouse_id,

    facility_name,
    facility_address AS address,
    borough,
    postcode,

    community_board,
    community_council,
    census_tract,

    bin,
    bbl,
    nta,

    latitude,
    longitude,

    ST_Transform(
        ST_SetSRID(
            ST_MakePoint(longitude, latitude),
            4326
        ),
        2263
    )::geometry(Point, 2263) AS geom

FROM raw.fdny_firehouses;


/* ============================================================
   2. TABLE / COLUMN COMMENTS
   ============================================================ */

COMMENT ON TABLE core.firehouses IS
'Cleaned FDNY firehouse locations prepared from raw.fdny_firehouses for spatial analysis.';

COMMENT ON COLUMN core.firehouses.firehouse_id IS
'Project-specific identifier assigned during core transformation.';

COMMENT ON COLUMN core.firehouses.geom IS
'Firehouse point geometry in EPSG:2263.';

COMMENT ON COLUMN core.firehouses.latitude IS
'Source latitude in WGS 84.';

COMMENT ON COLUMN core.firehouses.longitude IS
'Source longitude in WGS 84.';


/* ============================================================
   3. SPATIAL INDEX
   ============================================================ */

CREATE INDEX firehouses_geom_gix
ON core.firehouses
USING GIST (geom);


/* ============================================================
   4. ATTRIBUTE INDEXES
   ============================================================ */

CREATE INDEX firehouses_bbl_idx
ON core.firehouses (bbl);

CREATE INDEX firehouses_borough_idx
ON core.firehouses (borough);


/* ============================================================
   5. TABLE ANALYZE
   ============================================================ */

ANALYZE core.firehouses;


/* ============================================================
   6. CORE TABLE QC
   ============================================================ */


/*
    6.1 Record count

    Expected:
        219
*/

SELECT COUNT(*) AS firehouse_count
FROM core.firehouses;


/*
    6.2 Geometry type and CRS

    Expected:
        ST_Point
        EPSG:2263
*/

SELECT
    ST_GeometryType(geom) AS geometry_type,
    ST_SRID(geom) AS srid,
    COUNT(*) AS feature_count
FROM core.firehouses
GROUP BY
    ST_GeometryType(geom),
    ST_SRID(geom);


/*
    6.3 Geometry validity

    Expected:
        0 NULL
        0 empty
        0 invalid
*/

SELECT
    COUNT(*) AS total_features,

    COUNT(*) FILTER (
        WHERE geom IS NULL
    ) AS null_geometry,

    COUNT(*) FILTER (
        WHERE ST_IsEmpty(geom)
    ) AS empty_geometry,

    COUNT(*) FILTER (
        WHERE NOT ST_IsValid(geom)
    ) AS invalid_geometry

FROM core.firehouses;


/*
    6.4 Coordinate consistency

    Compare the stored geometry with the source latitude/
    longitude values.

    The geometry should reproduce the source coordinates
    after transformation back to EPSG:4326.
*/

SELECT
    MAX(
        ST_Distance(
            ST_Transform(geom, 4326)::geography,
            ST_SetSRID(
                ST_MakePoint(longitude, latitude),
                4326
            )::geography
        )
    ) AS max_coordinate_difference_meters
FROM core.firehouses;


/*
    6.5 Duplicate project identifiers

    Expected:
        duplicate_ids = 0
*/

SELECT
    COUNT(*) - COUNT(DISTINCT firehouse_id) AS duplicate_ids
FROM core.firehouses;


/*
    6.6 Borough distribution

    Compare against the raw layer.
*/

SELECT
    borough,
    COUNT(*) AS firehouse_count
FROM core.firehouses
GROUP BY borough
ORDER BY borough;


/*
    6.7 Spatial extent
*/

SELECT
    ST_XMin(extent) AS min_x,
    ST_YMin(extent) AS min_y,
    ST_XMax(extent) AS max_x,
    ST_YMax(extent) AS max_y
FROM (
    SELECT ST_Extent(geom) AS extent
    FROM core.firehouses
) AS e;


/* ============================================================
   7. OPTIONAL PERFORMANCE CHECK
   ============================================================ */


/*
    This confirms that PostgreSQL has a spatial index available
    for the geometry column.

    The index itself is created above; this query simply lists
    the indexes associated with the table.
*/

SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'core'
  AND tablename = 'firehouses';