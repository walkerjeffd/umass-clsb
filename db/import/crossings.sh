#!/bin/bash
# Import crossings from csv file to crossings table
# must run r/import-crossings.R first to generate csv file
# usage: ./crossings.sh <dbname> ../../r/csv/crossings.csv

set -eu

DB=$1
FILE=$2

echo Importing "$FILE" to table crossings...
psql -d "$1" -c "\copy crossings(id, x_coord, y_coord) FROM '$FILE' WITH CSV HEADER"
psql -d "$1" -c "UPDATE crossings SET geom = ST_SetSRID(ST_MakePoint(x_coord, y_coord), 5070)"
