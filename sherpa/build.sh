#!/bin/bash

SHA=`cd sherpa; git log -n 1 --pretty=format:'%h' --abbrev-commit`
docker-compose -f sherpa/docker-compose-prod.yml -p ${SHA} pull
docker-compose -f sherpa/docker-compose-prod.yml -p ${SHA} build
