#!/bin/bash
echo -e "\n$(date): pulling sherpa-prod..." >> /cron/logfile 2>&1
/cron/pull.sh >> /cron/logfile 2>&1

echo -e "\n$(date): Running on sherpa@$(/cron/sha.sh): $@" >> /cron/logfile 2>&1
docker-compose -f /cron/sherpa-prod/sherpa/sherpa/production.yml -p $(/cron/sha.sh) run --rm sherpa $@ >> /cron/logfile 2>&1
STATUS_CODE=$?
echo -e "\n$(date): Process exited with status code ${STATUS_CODE}" >> /cron/logfile 2>&1
