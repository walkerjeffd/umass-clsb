#!/bin/bash
# Import graph edges from csv file to edges_csv table
# run r/db-graph.R first to generate csv file
# nodes must already be imported
# usage: ./edges.sh ../../r/csv/graph-edges.csv

set -eu

. ../../config.sh

FILE=$1

echo Creating schema...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "
DROP TABLE IF EXISTS edges_csv;
CREATE TABLE edges_csv (
  id SERIAL PRIMARY KEY,
  start_id BIGINT,
  end_id BIGINT,
  length INT,
  cost REAL,
  value REAL
);
"

echo Importing "$FILE" to table edges_csv...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "\copy edges_csv(start_id, end_id, length, cost, value) FROM '$FILE' WITH CSV HEADER"

echo Done!
