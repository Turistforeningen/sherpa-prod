#!/bin/bash
PSQL="gosu postgres psql -h $POSTGRES_PORT_5432_TCP_ADDR"
SSH_IDENTITY_FILE="/private-data/sherpa.pem"

if [ ! -f $SSH_IDENTITY_FILE ]; then
  echo "Missing SSH identity file '$SSH_IDENTITY_FILE'"
  echo "Expected data to be mounted as a volume from the host."
  exit 1
fi

echo "Setting up a new database..."

$PSQL -e <<EOSQL
DROP DATABASE IF EXISTS sherpa;
CREATE DATABASE sherpa template template_postgis lc_collate 'nb_NO.utf8' lc_ctype 'nb_NO.utf8';
EOSQL

#$PSQL -e sherpa <<EOSQL
#CREATE EXTENSION postgis;
#CREATE EXTENSION postgis_topology;
#EOSQL

echo "Downloading database from production..."
ssh -i $SSH_IDENTITY_FILE \
    -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no ubuntu@www.turistforeningen.no "~/tools/exportdb.sh" > ./db.tmp

echo "Restoring with postgis_restore.pl..."
POSTGIS_CONFIG=/usr/share/postgresql/$PG_MAJOR/contrib/postgis-$POSTGIS_MAJOR
$POSTGIS_CONFIG/postgis_restore.pl ./db.tmp | $PSQL -e sherpa

echo "Cleaning up..."
rm -fv ./db.tmp*

