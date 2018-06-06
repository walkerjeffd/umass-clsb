#!/bin/bash
# Export huc8 polygons as geojson
# usage: ./huc8-geojson.sh <dbname> <output path>
# example: ./huc8-geojson.sh clsb ../../r/geojson/huc8.geojson

set -eu

DB=$1
FILE=$2

# simplify tolerance in projected units (meters)

echo -n Exporting "$FILE" from "$DB"...
ogr2ogr -f "GeoJSON" "$FILE" "PG:dbname=$DB" -t_srs EPSG:4326 -sql "select w.huc8, w.name, w.geom from wbdhu8 w where exists (select 1 from crossings c where st_intersects(w.geom, c.geom) limit 1);" -simplify 100
echo done