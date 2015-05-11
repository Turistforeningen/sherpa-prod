#!/bin/bash

COMPOSE_FILE=sherpa/docker-compose-prod.yml
SHA="`cd sherpa; git log -n 1 --pretty=format:'%h' --abbrev-commit`"

if [[ $1 == "-h" || $1 == "--help" ]]; then
  echo "Usage: logs.sh [SERVICE [SERVICE ..]]"
  exit 0
fi

docker-compose -f ${COMPOSE_FILE} -p ${SHA} logs $@
