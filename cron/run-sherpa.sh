#!/bin/bash
/cron/pull.sh
echo
echo "$(date): Running on sherpa@$(/cron/sha.sh): $@" >> /cron/logfile 2>&1
docker-compose -f /cron/sherpa-prod/sherpa/sherpa/docker-compose-prod.yml -p $(/cron/sha.sh) run --rm sherpa $@ >> /cron/logfile 2>&1
