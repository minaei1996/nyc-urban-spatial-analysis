CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS analysis;

COMMENT ON SCHEMA raw IS
'Raw source datasets imported into PostgreSQL/PostGIS.';

COMMENT ON SCHEMA core IS
'Cleaned and standardized spatial datasets used for analysis.';

COMMENT ON SCHEMA analysis IS
'Derived analytical tables and views.';