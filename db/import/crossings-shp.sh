#!/bin/bash
# Import crossings from shapefile file to crossings table
# usage: ./crossings.sh </path/to/DSL_critical_linkages_culverts_v3.0.shp>

set -eu

TABLE=crossings
FILE=$1

. ../../config.sh

echo Importing $FILE to table $TABLE...
ogr2ogr -f "PostgreSQL" PG:"$SHEDS_CLSB_DB_CONNSTRING" $FILE -t_srs EPSG:5070 -nln $TABLE -nlt POINT -overwrite -lco GEOMETRY_NAME=geom
