#!/bin/bash
# Export states polygons as geojson
# usage: ./states-geojson.sh <output path>
# example: ./states-geojson.sh ../api/static/states.json

set -eu

FILE=$1

. ../../config.sh

echo -n Exporting "$FILE"...
ogr2ogr -f "GeoJSON" "$FILE" "PG:dbname=$SHEDS_CLSB_DB_CONNSTRING" -t_srs EPSG:4326 -sql "select stusps, name, geom from states" -lco SIGNIFICANT_FIGURES=8 -simplify 0.001
echo done
