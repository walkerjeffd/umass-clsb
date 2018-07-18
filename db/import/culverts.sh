#!/bin/bash
# Import culverts from shapefile file to culverts table
# usage: ./culverts.sh </path/to/DSL_critical_linkages_culverts_v3.0.shp>

set -eu

TABLE=culverts
FILE=$1

. ../../config.sh

echo Importing $FILE to table $TABLE...
ogr2ogr -f "PostgreSQL" PG:"$SHEDS_CLSB_DB_CONNSTRING" $FILE -nln $TABLE -nlt POINT -overwrite -lco GEOMETRY_NAME=geom
