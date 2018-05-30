#!/bin/bash
# Import crossings from csv file to crossings table
# must run r/import-crossings.R first to generate csv file
# usage: ./crossings.sh ../../r/csv/crossings.csv

set -eu

FILE=$1

psql -d clsb -c "\copy crossings(id, x_coord, y_coord) FROM '$FILE' WITH CSV HEADER"
psql -d clsb -c "UPDATE crossings SET geom = ST_SetSRID(ST_MakePoint(x_coord, y_coord), 5070)"
