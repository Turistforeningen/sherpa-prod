#!/bin/bash

COMPOSE_FILE=sherpa/sherpa/docker-compose-prod.yml

DEPLOYMENT_METHOD=$1
SHERPA_COMMIT=$2
SHERPA_BRANCH=$3

case "${DEPLOYMENT_METHOD}" in
  soft)
    echo "Initiating soft deployment..."
    ;;

  hard)
    echo "Initiating hard deployment..."
    ;;

  *)
    echo "Usage: $0 soft|hard [commit[ branch]]"
    exit 1
    ;;
esac

if [ -z ${SHERPA_COMMIT} ]; then
  SHERPA_COMMIT=HEAD
fi

if [ -z ${SHERPA_BRANCH} ]; then
  SHERPA_BRANCH=docker-prod-settings
fi

# Update submodules
git pull
git submodule update --init --recursive

OLD_SHA="`cd sherpa/sherpa; git log -n 1 --pretty=format:'%h' --abbrev-commit`"
OLD_HOST=`docker-compose -f ${COMPOSE_FILE} -p ${OLD_SHA} port www 8080`
OLD_PORT=`echo ${OLD_HOST} | sed 's/0.0.0.0://'`
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

# Hard deployments: remove the current backend before migrating
if [ "$DEPLOYMENT_METHOD" = "hard" ]; then
  echo "Removing current backend from rotation..."
  docker exec -it haproxy ./route-backend.sh
fi

# Migrate
echo "Running database migrations..."
docker-compose -f ${COMPOSE_FILE} -p ${NEW_SHA} run --rm sherpa ./manage.py migrate

# Check migration status
MIGRATION_STATUS=$?
if [ $MIGRATION_STATUS -ne 0 ]; then
  echo "Migration exited with code $MIGRATION_STATUS; aborting deployment..."

  # Re-add the old deployment backend
  if [ "$DEPLOYMENT_METHOD" = "hard" ]; then
    echo "Re-adding the previous deployment backend."
    docker exec -it haproxy ./route-backend.sh ${OLD_PORT}
  fi
  exit 1
fi

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

  # Hard deployments: Ask user to clean up the database before re-enabling previous deployment
  if [ "$DEPLOYMENT_METHOD" = "hard" ]; then
    echo

    read -p "Open a shell to roll back migrations? [y/N] " yn
    case $yn in
      [Yy]*) docker-compose -f ${COMPOSE_FILE} -p ${NEW_SHA} run --rm sherpa /bin/bash ;;
    esac

    read -p "Re-enable the previous deployment? [y/N] " yn
    case $yn in
      [Yy]*) docker exec -it haproxy ./route-backend.sh ${OLD_PORT};;
    esac

    echo "Done, now go clean up your mess."
  fi
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
