-- ============================================================
-- Core: Rite Aid Pharmacies
-- Source: raw.rite_aid
--
-- Purpose:
--   Convert the source pharmacy WKB/EWKB text into PostGIS
--   point geometries and standardize the spatial reference
--   system for analysis.
--
-- Source attributes:
--   geometry_wkb -> Rite Aid location point, EWKB, EPSG:4326
--   building_id  -> NYC BBL identifying the associated
--                    MapPLUTO parcel
--   pharm_id     -> source pharmacy/OSM identifier
--
-- Spatial reference systems:
--   EPSG:4326  - WGS 84 geographic coordinates
--   EPSG:2263  - NAD83 / New York Long Island (ftUS)
--
-- Notes:
--   - The source WKB/EWKB value is stored as hexadecimal text.
--   - ST_GeomFromEWKB() is used after converting the hexadecimal
--     text to bytea with decode(..., 'hex').
--   - The source building_id was verified against MapPLUTO:
--       raw.rite_aid.building_id = raw."MapPLUTO"."BBL"
--     for all 100 pharmacy records.
--   - The source pharm_geometry_wkb is intentionally not promoted
--     into the core table because its spatial relationship to the
--     individual pharmacy records has not been established.
--   - The raw source field remains available in raw.rite_aid.
-- ============================================================


DROP TABLE IF EXISTS core.pharmacies;


CREATE TABLE core.pharmacies (
    pharmacy_id    BIGINT PRIMARY KEY,
    bbl            BIGINT,
    pharm_id       TEXT,
    name           TEXT,
    geom_4326      geometry(Point, 4326),
    geom           geometry(Point, 2263)
);


INSERT INTO core.pharmacies (
    pharmacy_id,
    bbl,
    pharm_id,
    name,
    geom_4326,
    geom
)
SELECT
    ROW_NUMBER() OVER (
        ORDER BY building_id, pharm_id, name
    )::BIGINT AS pharmacy_id,

    building_id AS bbl,

    pharm_id,

    name,

    ST_GeomFromEWKB(
        decode(geometry_wkb, 'hex')
    )::geometry(Point, 4326) AS geom_4326,

    ST_Transform(
        ST_GeomFromEWKB(
            decode(geometry_wkb, 'hex')
        ),
        2263
    )::geometry(Point, 2263) AS geom

FROM raw.rite_aid;


-- ============================================================
-- Documentation
-- ============================================================

COMMENT ON TABLE core.pharmacies IS
'Standardized Rite Aid pharmacy locations with NYC BBL identifiers and PostGIS point geometries.';

COMMENT ON COLUMN core.pharmacies.pharmacy_id IS
'Project-generated identifier for each pharmacy record.';

COMMENT ON COLUMN core.pharmacies.bbl IS
'NYC Borough-Block-Lot identifier linking the pharmacy record to the corresponding MapPLUTO parcel. Verified against raw."MapPLUTO"."BBL".';

COMMENT ON COLUMN core.pharmacies.pharm_id IS
'Pharmacy/source identifier provided by the source dataset.';

COMMENT ON COLUMN core.pharmacies.geom_4326 IS
'Rite Aid pharmacy location in WGS 84 geographic coordinates (EPSG:4326).';

COMMENT ON COLUMN core.pharmacies.geom IS
'Rite Aid pharmacy location projected to NAD83 / New York Long Island ftUS (EPSG:2263).';


-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX pharmacies_geom_4326_gix
ON core.pharmacies
USING GIST (geom_4326);

CREATE INDEX pharmacies_geom_gix
ON core.pharmacies
USING GIST (geom);

CREATE INDEX pharmacies_bbl_idx
ON core.pharmacies (bbl);

CREATE INDEX pharmacies_pharm_id_idx
ON core.pharmacies (pharm_id);


ANALYZE core.pharmacies;


-- ============================================================
-- Quality Control
-- ============================================================

-- 1. Row count
SELECT
    COUNT(*) AS row_count
FROM core.pharmacies;


-- 2. Geometry type and SRID
SELECT
    ST_GeometryType(geom) AS geometry_type,
    ST_SRID(geom) AS srid,
    COUNT(*) AS feature_count
FROM core.pharmacies
GROUP BY
    ST_GeometryType(geom),
    ST_SRID(geom);


-- 3. Null geometry check
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE geom IS NULL
    ) AS missing_geometry
FROM core.pharmacies;


-- 4. Geometry validity
SELECT
    COUNT(*) AS total_geometries,
    COUNT(*) FILTER (
        WHERE ST_IsValid(geom)
    ) AS valid_geometries,
    COUNT(*) FILTER (
        WHERE NOT ST_IsValid(geom)
    ) AS invalid_geometries
FROM core.pharmacies;


-- 5. Check duplicate source records
SELECT
    bbl,
    pharm_id,
    COUNT(*) AS duplicate_count
FROM core.pharmacies
GROUP BY
    bbl,
    pharm_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- 6. Check pharmacy source identifiers
--
-- A pharm_id can legitimately occur multiple times because the
-- source contains multiple BBL-associated records for the same
-- source pharmacy identifier.

SELECT
    pharm_id,
    COUNT(*) AS record_count,
    COUNT(DISTINCT bbl) AS distinct_bbl_count
FROM core.pharmacies
GROUP BY pharm_id
ORDER BY pharm_id;


-- 7. Verify the BBL relationship with MapPLUTO
--
-- Every pharmacy BBL should correspond to exactly one MapPLUTO
-- parcel in this project.

SELECT
    COUNT(*) AS pharmacy_records,
    COUNT(m."BBL") AS matched_parcels,
    COUNT(*) FILTER (
        WHERE m."BBL" IS NULL
    ) AS unmatched_parcels,
    COUNT(DISTINCT p.bbl) AS distinct_pharmacy_bbls,
    COUNT(DISTINCT m."BBL") AS distinct_matched_bbls
FROM core.pharmacies AS p
LEFT JOIN raw."MapPLUTO" AS m
    ON m."BBL" = p.bbl;


-- 8. Identify any pharmacy BBLs that match multiple MapPLUTO
--    records. This should return zero rows because BBL is unique
--    in the imported MapPLUTO dataset.

SELECT
    p.bbl,
    COUNT(m."BBL") AS mappluto_match_count
FROM core.pharmacies AS p
JOIN raw."MapPLUTO" AS m
    ON m."BBL" = p.bbl
GROUP BY p.bbl
HAVING COUNT(m."BBL") > 1
ORDER BY mappluto_match_count DESC;


-- 9. Coordinate transformation consistency
--
-- Compare the original EPSG:4326 point with the EPSG:2263
-- geometry transformed back to EPSG:4326.

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
FROM core.pharmacies;


-- 10. Spatial extent of pharmacy locations
SELECT
    ST_XMin(extent) AS min_x,
    ST_YMin(extent) AS min_y,
    ST_XMax(extent) AS max_x,
    ST_YMax(extent) AS max_y
FROM (
    SELECT ST_Extent(geom) AS extent
    FROM core.pharmacies
) AS e;


-- 11. Inspect pharmacy records and their MapPLUTO BBLs

SELECT
    p.pharmacy_id,
    p.bbl,
    p.pharm_id,
    p.name
FROM core.pharmacies AS p
ORDER BY p.pharmacy_id
LIMIT 20;
