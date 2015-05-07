#!/bin/bash

COMPOSE_FILE=sherpa/sherpa/docker-compose-prod.yml

SHERPA_COMMIT=$1
SHERPA_BRANCH=$2

if [ -z ${SHERPA_COMMIT} ]; then
  SHERPA_COMMIT=HEAD
fi

if [ -z ${SHERPA_BRANCH} ]; then
  SHERPA_BRANCH=docker-prod-settings
fi

# Update submodules
git pull origin master
git submodule update --init --recursive

OLD_SHA="`cd sherpa/sherpa; git log -n 1 --pretty=format:'%h' --abbrev-commit`"
echo "Previous build SHA was ${OLD_SHA}"

# Pull
echo "Updating Sherpa repo..."
(
  cd sherpa/sherpa
  git pull -f origin ${SHERPA_BRANCH}
  git reset --hard ${SHERPA_COMMIT}
  git submodule update --init --recursive
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

# Build successful; commit and push the new deployment
git commit -m "Deploy Turistforeningen/sherpa@${NEW_SHA}" sherpa/sherpa
git push
