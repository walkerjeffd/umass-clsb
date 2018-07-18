#!/bin/bash
# Import huc boundaries to database
# usage: ./wbd-huc.sh </path/to/NATIONAL_WBD_GDB.gdb>

set -eu

FILE=$1

echo Importing $FILE to database $SHEDS_CLSB_DB_DBNAME...
ogr2ogr -f "PostgreSQL" PG:"$SHEDS_CLSB_DB_CONNSTRING" -t_srs "EPSG:5070" "$FILE" WBDHU4 WBDHU6 WBDHU8 WBDHU10 WBDHU12 -lco OVERWRITE=YES -lco GEOMETRY_NAME=geom -lco DIM=2 -lco FID=fid -nlt MULTIPOLYGON
echo Done
