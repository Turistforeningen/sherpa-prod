#!/bin/bash
docker-compose -f /cron/sherpa-prod/sherpa/sherpa/docker-compose-prod.yml -p $(/cron/sha.sh) run --rm sherpa $@
