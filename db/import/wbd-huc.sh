#!/bin/bash
# Import huc boundaries to database
# usage: ./wbd-huc.sh <dbname> </path/to/NATIONAL_WBD_GDB.gdb>

set -eu

DB=$1
FILE=$2

echo -n Importing "$FILE" to "$DB"...
ogr2ogr -f PostgreSQL PG:dbname="$DB" -t_srs "EPSG:5070" "$FILE" WBDHU4 WBDHU6 WBDHU8 WBDHU10 WBDHU12 -lco OVERWRITE=YES -lco GEOMETRY_NAME=geom -lco DIM=2 -lco FID=fid -nlt MULTIPOLYGON
echo done
