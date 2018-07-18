#/bin/bash
# Initialize database
# usage: ./init.sh

set -eu

# load config
. ../config.sh

echo Creating database...
createdb -h $SHEDS_LMG_DB_HOST -p $SHEDS_LMG_DB_PORT -U $SHEDS_LMG_DB_USER $SHEDS_LMG_DB_DBNAME

echo Installing postgis...
psql -h $SHEDS_LMG_DB_HOST -p $SHEDS_LMG_DB_PORT -U $SHEDS_LMG_DB_USER -d $SHEDS_LMG_DB_DBNAME -c "CREATE EXTENSION postgis;"

echo Done!
