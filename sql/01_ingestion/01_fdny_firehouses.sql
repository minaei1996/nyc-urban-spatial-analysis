DROP TABLE IF EXISTS raw.fdny_firehouses;

CREATE TABLE raw.fdny_firehouses (
    facility_name       TEXT,
    facility_address    TEXT,
    borough             TEXT,
    postcode            INTEGER,
    latitude            DOUBLE PRECISION,
    longitude           DOUBLE PRECISION,
    community_board     INTEGER,
    community_council   INTEGER,
    census_tract        INTEGER,
    bin                 BIGINT,
    bbl                 BIGINT,
    nta                 TEXT
);