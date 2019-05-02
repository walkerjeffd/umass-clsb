#!/bin/bash
# Export boundary polygon as geojson
# usage: ./boundary-geojson.sh <output path>
# example: ./boundary-geojson.sh ../api/static/boundary.json

set -eu

FILE=$1

. ../../config.sh

echo -n Exporting "$FILE"...
ogr2ogr -f "GeoJSON" "$FILE" "PG:$SHEDS_CLSB_DB_CONNSTRING" -t_srs EPSG:4326 -lco SIGNIFICANT_FIGURES=8 -simplify 0.001 boundary
echo done
