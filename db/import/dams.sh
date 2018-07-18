#!/bin/bash
# Import dams from shapefile file to dams table
# usage: ./dams.sh </path/to/DSL_critical_linkages_dams_v3.0.shp>

set -eu

TABLE=dams
FILE=$1

. ../../config.sh

echo Importing $FILE to table $TABLE...
ogr2ogr -f "PostgreSQL" PG:"$SHEDS_CLSB_DB_CONNSTRING" $FILE -nln $TABLE -nlt POINT -overwrite -lco GEOMETRY_NAME=geom
