DROP TABLE IF EXISTS raw.rite_aid;

CREATE TABLE raw.rite_aid (
    geometry_wkb       TEXT,
    building_id        BIGINT,
    pharm_id           TEXT,
    name               TEXT,
    pharm_geometry_wkb TEXT
);