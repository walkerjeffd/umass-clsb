#!/bin/bash
# Export huc12 polygons as geojson
# usage: ./huc12-geojson.sh <output path>
# example: ./huc12-geojson.sh ../../r/geojson/huc12.geojson

set -eu

FILE=$1

. ../../config.sh

# simplify tolerance in projected units (meters)

echo -n Exporting "$FILE"...
ogr2ogr -f "GeoJSON" "$FILE" "PG:$SHEDS_CLSB_DB_CONNSTRING" -t_srs EPSG:4326 -sql "select w.huc12, w.name, w.geom from wbdhu12 w where exists (select 1 from barriers b where st_intersects(w.geom, b.geom) limit 1);" -simplify 100
echo done
