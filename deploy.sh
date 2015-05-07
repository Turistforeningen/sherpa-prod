#!/bin/bash

COMPOSE_FILE=sherpa/sherpa/docker-compose-prod.yml

OLD_SHA="`cd sherpa/sherpa; git log -n 1 --pretty=format:'%h' --abbrev-commit`"
echo "Previous build SHA was ${OLD_SHA}"

# Updat
echo "Updating Sherpa repo..."
(
  cd sherpa/sherpa
  git pull -f origin
  git reset --hard HEAD
  git submodule update
)

NEW_SHA="`cd sherpa/sherpa; git log -n 1 --pretty=format:'%h' --abbrev-commit`"
echo "New build SHA is ${OLD_SHA}"

# Build
echo "Building Sherpa containers..."
docker-compose -f ${COMPOSE_FILE} -p ${NEW_SHA} pull
docker-compose -f ${COMPOSE_FILE} -p ${NEW_SHA} build

# Migrate
echo "Running database migrations..."
docker-compose -f ${COMPOSE_FILE} -p ${NEW_SHA} run --rm sherpa ./manage.py migrate

# Start
echo "Starting Sherpa containers..."
docker-compose -f ${COMPOSE_FILE} -p ${NEW_SHA} up -d

HOST=`docker-compose -f ${COMPOSE_FILE} -p ${NEW_SHA} port www 8080`
PORT=`echo ${HOST} | sed 's/0.0.0.0://'`

# Check port
if [ -z ${PORT} ]; then
  docker-compose -f ${COMPOSE_FILE} -p ${NEW_SHA} ps
  echo "New builds appears to have no exposed port! Who broke the build?"
  echo "https://youtu.be/DJ001Kgz5wc"
  exit 1
fi

# CURL like you mean it!
# curl --verbose -o /dev/null -H "Host: www.dnt.no" 0.0.0.0:32776/
# curl -sI -H "Host: www.dnt.no" ${HOST} | grep HTTP
# lurl -sI -H "Host: www.dnt.no" ${HOST} | grep HTTP
# curl -sI -H "Host: www.dnt.no" ${HOST} | grep HTTP
# curl -sI -H "Host: www.dnt.no" ${HOST} | grep HTTP

# Route
echo "Update HAProxy route..."
docker exec -it haproxy ./route-backend.sh ${PORT}

# Stop old
if [[ -n ${OLD_SHA} && "${OLD_SHA}" != "${NEW_SHA}" ]]; then
  echo "Stopping old Sherpa containers..."
  docker-compose -f ${COMPOSE_FILE} -p ${OLD_SHA} stop
fi
