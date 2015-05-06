#!/bin/bash

SHA=`cd sherpa; git log -n 1 --pretty=format:'%h' --abbrev-commit`
docker-compose -f sherpa/docker-compose-prod.yml -p ${SHA} up -d
docker-compose -f sherpa/docker-compose-prod.yml -p ${SHA} ps
