#!/bin/sh
POSTGRES="gosu postgres postgres"

$POSTGRES --single -E <<EOSQL
CREATE DATABASE sherpa template template_postgis lc_collate 'nb_NO.utf8' lc_ctype 'nb_NO.utf8';
EOSQL

#$POSTGRES --single sherpa -d 2 -E <<EOSQL
#CREATE EXTENSION postgis;
#CREATE EXTENSION postgis_topology;
#EOSQL

