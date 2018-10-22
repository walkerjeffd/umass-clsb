#!/bin/bash
# Export huc8 polygons as geojson
# usage: ./huc8-geojson.sh <output path>
# example: ./huc8-geojson.sh ../../r/geojson/huc8.geojson

set -eu

FILE=$1

. ../../config.sh

# simplify tolerance in projected units (meters)

echo -n Exporting "$FILE"...
ogr2ogr -f "GeoJSON" "$FILE" "PG:dbname=$SHEDS_CLSB_DB_CONNSTRING" -t_srs EPSG:4326 -sql "select w.huc8, w.name, w.geom from wbdhu8 w where exists (select 1 from crossings c where st_intersects(w.geom, c.geom) limit 1);" -simplify 500
echo done
