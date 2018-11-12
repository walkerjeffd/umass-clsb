#!/bin/bash
# Import states from shapefile file to states table
# Download TIGER/Line Shapefiles from https://www.census.gov/geo/maps-data/data/tiger-line.html
# usage: ./states.sh </path/to/tl_2018_us_state.shp>

set -eu

TABLE=states
FILE=$1

. ../../config.sh

echo Importing $FILE to table $TABLE...
ogr2ogr -f "PostgreSQL" PG:"$SHEDS_CLSB_DB_CONNSTRING" $FILE -nln $TABLE -s_srs EPSG:4269 -t_srs EPSG:4326 -nlt MULTIPOLYGON -overwrite -lco GEOMETRY_NAME=geom -where "stusps IN ('CT', 'DC', 'DE', 'MA', 'MD', 'ME', 'NH', 'NJ', 'NY', 'PA', 'RI', 'VA', 'VT', 'WV')"
