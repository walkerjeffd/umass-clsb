-- set up schema

CREATE EXTENSION postgis;

CREATE TABLE crossings (
  id SERIAL PRIMARY KEY,
  x_coord REAL,
  y_coord REAL,
  geom GEOMETRY(POINT, 5070)
);

CREATE INDEX crossings_geom_gix ON crossings USING gist(geom);

-- CREATE TABLE huc12 (

-- );

