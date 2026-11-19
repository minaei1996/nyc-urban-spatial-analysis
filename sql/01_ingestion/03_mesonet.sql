DROP TABLE IF EXISTS raw.mesonet;

CREATE TABLE raw.mesonet (
    station                     TEXT,
    time_end                    TEXT,
    latitude                    DOUBLE PRECISION,
    longitude                   DOUBLE PRECISION,
    elevation_m                 DOUBLE PRECISION,
    temp_2m_max_c               DOUBLE PRECISION,
    temp_2m_min_c               DOUBLE PRECISION,
    temp_2m_avg_c               DOUBLE PRECISION,
    apparent_temperature_max_c  DOUBLE PRECISION,
    apparent_temperature_min_c  DOUBLE PRECISION,
    apparent_temperature_avg_c  DOUBLE PRECISION
);