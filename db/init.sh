#/bin/bash
# Initialize database
# usage: ./init.sh

set -eu

# load config
. ../config.sh

echo Creating database...
createdb -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER $SHEDS_CLSB_DB_DBNAME

echo Installing postgis...
psql -h $SHEDS_CLSB_DB_HOST -p $SHEDS_CLSB_DB_PORT -U $SHEDS_CLSB_DB_USER -d $SHEDS_CLSB_DB_DBNAME -c "CREATE EXTENSION postgis;"

echo Done!
