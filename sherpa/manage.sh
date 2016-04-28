#!/bin/bash

COMPOSE_FILE=sherpa/production.yml
SHA="`cd sherpa; git log -n 1 --pretty=format:'%h' --abbrev-commit`"

if [[ $1 == "-h" || $1 == "--help" ]]; then
  echo "Usage: $0"
  exit 0
fi

docker-compose -f ${COMPOSE_FILE} -p ${SHA} run --rm sherpa ./manage.py "$@"
