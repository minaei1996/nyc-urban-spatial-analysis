-- ============================================================
-- Core: NYC MapPLUTO Parcels
-- Source: raw."MapPLUTO"
--
-- Purpose:
--   Convert the raw MapPLUTO dataset into a cleaned and
--   standardized parcel layer for spatial analysis.
--
-- Spatial reference system:
--   EPSG:2263 - NAD83 / New York Long Island (ftUS)
--
-- Key relationship:
--   bbl is the NYC Borough-Block-Lot identifier and serves as
--   the primary key for the analytical parcel table.
--
-- Notes:
--   - The raw MapPLUTO geometry is already MultiPolygon/2263.
--   - Only attributes relevant to this project's analyses are
--     promoted into the core table.
--   - Raw MapPLUTO values remain unchanged in raw."MapPLUTO".
--   - YearBuilt = 0 in the source is treated as missing in core.
--   - Other unusual YearBuilt values are retained for QC rather
--     than silently modified.
-- ============================================================


DROP TABLE IF EXISTS core.parcels;


CREATE TABLE core.parcels (
    bbl             BIGINT PRIMARY KEY,
    borough         TEXT,
    block           INTEGER,
    lot             INTEGER,
    zipcode         INTEGER,

    address         TEXT,

    zoning          TEXT,
    land_use        TEXT,
    building_class  TEXT,

    lot_area        DOUBLE PRECISION,
    building_area   DOUBLE PRECISION,
    commercial_area DOUBLE PRECISION,
    residential_area DOUBLE PRECISION,
    office_area     DOUBLE PRECISION,
    retail_area     DOUBLE PRECISION,
    garage_area     DOUBLE PRECISION,
    storage_area    DOUBLE PRECISION,
    factory_area    DOUBLE PRECISION,
    other_area      DOUBLE PRECISION,

    num_buildings   INTEGER,
    num_floors      DOUBLE PRECISION,
    units_res       INTEGER,
    units_total     INTEGER,

    lot_front       DOUBLE PRECISION,
    lot_depth       DOUBLE PRECISION,
    building_front DOUBLE PRECISION,
    building_depth  DOUBLE PRECISION,

    year_built      INTEGER,

    assess_land     DOUBLE PRECISION,
    assess_total    DOUBLE PRECISION,

    x_coord         DOUBLE PRECISION,
    y_coord         DOUBLE PRECISION,

    latitude        DOUBLE PRECISION,
    longitude       DOUBLE PRECISION,

    geom            geometry(MultiPolygon, 2263)
);


INSERT INTO core.parcels (
    bbl,
    borough,
    block,
    lot,
    zipcode,
    address,
    zoning,
    land_use,
    building_class,

    lot_area,
    building_area,
    commercial_area,
    residential_area,
    office_area,
    retail_area,
    garage_area,
    storage_area,
    factory_area,
    other_area,

    num_buildings,
    num_floors,
    units_res,
    units_total,

    lot_front,
    lot_depth,
    building_front,
    building_depth,

    year_built,

    assess_land,
    assess_total,

    x_coord,
    y_coord,

    latitude,
    longitude,

    geom
)
SELECT
    "BBL"::BIGINT AS bbl,
    "Borough" AS borough,
    "Block"::INTEGER AS block,
    "Lot"::INTEGER AS lot,
    "ZipCode"::INTEGER AS zipcode,

    "Address" AS address,

    "ZoneDist1" AS zoning,
    "LandUse" AS land_use,
    "BldgClass" AS building_class,

    "LotArea"::DOUBLE PRECISION AS lot_area,
    "BldgArea"::DOUBLE PRECISION AS building_area,
    "ComArea"::DOUBLE PRECISION AS commercial_area,
    "ResArea"::DOUBLE PRECISION AS residential_area,
    "OfficeArea"::DOUBLE PRECISION AS office_area,
    "RetailArea"::DOUBLE PRECISION AS retail_area,
    "GarageArea"::DOUBLE PRECISION AS garage_area,
    "StrgeArea"::DOUBLE PRECISION AS storage_area,
    "FactryArea"::DOUBLE PRECISION AS factory_area,
    "OtherArea"::DOUBLE PRECISION AS other_area,

    "NumBldgs"::INTEGER AS num_buildings,
    "NumFloors"::DOUBLE PRECISION AS num_floors,
    "UnitsRes"::INTEGER AS units_res,
    "UnitsTotal"::INTEGER AS units_total,

    "LotFront"::DOUBLE PRECISION AS lot_front,
    "LotDepth"::DOUBLE PRECISION AS lot_depth,
    "BldgFront"::DOUBLE PRECISION AS building_front,
    "BldgDepth"::DOUBLE PRECISION AS building_depth,

    NULLIF("YearBuilt"::INTEGER, 0) AS year_built,

    "AssessLand"::DOUBLE PRECISION AS assess_land,
    "AssessTot"::DOUBLE PRECISION AS assess_total,

    "XCoord"::DOUBLE PRECISION AS x_coord,
    "YCoord"::DOUBLE PRECISION AS y_coord,

    "Latitude"::DOUBLE PRECISION AS latitude,
    "Longitude"::DOUBLE PRECISION AS longitude,

    geom::geometry(MultiPolygon, 2263) AS geom

FROM raw."MapPLUTO";


-- ============================================================
-- Documentation
-- ============================================================

COMMENT ON TABLE core.parcels IS
'Standardized NYC MapPLUTO parcel layer used as the primary parcel dataset for spatial and property analysis. One row represents one unique NYC Borough-Block-Lot (BBL).';

COMMENT ON COLUMN core.parcels.bbl IS
'NYC Borough-Block-Lot identifier. Serves as the primary key and relationship key for parcel-level analysis.';

COMMENT ON COLUMN core.parcels.year_built IS
'Year the building was built. Source value 0 is standardized to NULL because it represents missing/unknown year information. Other unusual source values are retained for QC.';

COMMENT ON COLUMN core.parcels.geom IS
'NYC parcel geometry in NAD83 / New York Long Island ftUS (EPSG:2263).';


-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX parcels_geom_gix
ON core.parcels
USING GIST (geom);

CREATE INDEX parcels_borough_idx
ON core.parcels (borough);

CREATE INDEX parcels_land_use_idx
ON core.parcels (land_use);

CREATE INDEX parcels_building_class_idx
ON core.parcels (building_class);

CREATE INDEX parcels_block_lot_idx
ON core.parcels (block, lot);

CREATE INDEX parcels_zipcode_idx
ON core.parcels (zipcode);


ANALYZE core.parcels;


-- ============================================================
-- Quality Control
-- ============================================================

-- 1. Row count
SELECT
    COUNT(*) AS row_count
FROM core.parcels;


-- 2. BBL uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT bbl) AS unique_bbls
FROM core.parcels;


-- 3. Geometry type and SRID
SELECT
    ST_GeometryType(geom) AS geometry_type,
    ST_SRID(geom) AS srid,
    COUNT(*) AS feature_count
FROM core.parcels
GROUP BY
    ST_GeometryType(geom),
    ST_SRID(geom);


-- 4. Geometry completeness and validity
SELECT
    COUNT(*) AS total_geometries,
    COUNT(*) FILTER (
        WHERE geom IS NULL
    ) AS missing_geometry,
    COUNT(*) FILTER (
        WHERE ST_IsEmpty(geom)
    ) AS empty_geometry,
    COUNT(*) FILTER (
        WHERE ST_IsValid(geom)
    ) AS valid_geometries,
    COUNT(*) FILTER (
        WHERE NOT ST_IsValid(geom)
    ) AS invalid_geometries
FROM core.parcels;


-- 5. Spatial extent
SELECT
    ST_XMin(extent) AS min_x,
    ST_YMin(extent) AS min_y,
    ST_XMax(extent) AS max_x,
    ST_YMax(extent) AS max_y
FROM (
    SELECT ST_Extent(geom) AS extent
    FROM core.parcels
) AS e;


-- 6. Borough distribution
SELECT
    borough,
    COUNT(*) AS parcel_count
FROM core.parcels
GROUP BY borough
ORDER BY parcel_count DESC;


-- 7. Land-use distribution
SELECT
    land_use,
    COUNT(*) AS parcel_count
FROM core.parcels
GROUP BY land_use
ORDER BY parcel_count DESC;


-- 8. Missing / suspicious YearBuilt values
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE year_built IS NULL
    ) AS missing_year_built,
    MIN(year_built) AS minimum_year_built,
    MAX(year_built) AS maximum_year_built
FROM core.parcels;


-- 9. Source YearBuilt values that are unusual
--    These are checked against the raw source without modifying it.
SELECT
    "YearBuilt" AS source_year_built,
    COUNT(*) AS parcel_count
FROM raw."MapPLUTO"
WHERE "YearBuilt" NOT BETWEEN 1600 AND 2026
  AND "YearBuilt" <> 0
GROUP BY "YearBuilt"
ORDER BY source_year_built;


-- 10. Numeric sanity checks
SELECT
    COUNT(*) FILTER (
        WHERE lot_area < 0
    ) AS negative_lot_area,
    COUNT(*) FILTER (
        WHERE building_area < 0
    ) AS negative_building_area,
    COUNT(*) FILTER (
        WHERE num_buildings < 0
    ) AS negative_num_buildings,
    COUNT(*) FILTER (
        WHERE num_floors < 0
    ) AS negative_num_floors,
    COUNT(*) FILTER (
        WHERE units_res < 0
    ) AS negative_residential_units,
    COUNT(*) FILTER (
        WHERE units_total < 0
    ) AS negative_total_units
FROM core.parcels;


-- 11. Building-area / lot-area relationship
--
-- BuildingArea represents total floor area, while LotArea
-- represents land area. Therefore BuildingArea > LotArea is
-- possible and is not inherently an error.
--
-- Report the distribution rather than treating it as invalid.

SELECT
    COUNT(*) AS total_parcels,
    COUNT(*) FILTER (
        WHERE building_area > lot_area
    ) AS building_area_greater_than_lot_area,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE building_area > lot_area
        ) / COUNT(*),
        2
    ) AS percent_building_area_greater_than_lot_area
FROM core.parcels;


-- 11b. Parcels with no building area
SELECT
    COUNT(*) AS parcels_with_zero_building_area
FROM core.parcels
WHERE building_area = 0;


-- 11c. Parcels with buildings but no recorded residential units
SELECT
    COUNT(*) AS parcels_with_buildings_but_zero_residential_units
FROM core.parcels
WHERE building_area > 0
  AND units_res = 0;


-- 12. Pharmacy-to-parcel relationship
--     Every pharmacy should reference an existing BBL.
SELECT
    COUNT(*) AS pharmacy_records,
    COUNT(p.bbl) AS matched_parcels,
    COUNT(*) FILTER (
        WHERE p.bbl IS NULL
    ) AS unmatched_parcels
FROM core.pharmacies AS ph
LEFT JOIN core.parcels AS p
    ON p.bbl = ph.bbl;


-- 13. Sample records
SELECT
    bbl,
    borough,
    block,
    lot,
    land_use,
    building_class,
    lot_area,
    building_area,
    num_floors,
    units_res,
    units_total,
    year_built
FROM core.parcels
ORDER BY bbl
LIMIT 20;