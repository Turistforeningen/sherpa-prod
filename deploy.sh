#!/bin/bash

COMPOSE_FILE=sherpa/sherpa/production.yml

DEPLOYMENT_METHOD=$1
SHERPA_COMMIT=$2
SHERPA_BRANCH=$3

DOCKER_MACHINE_ACTIVE=`docker-machine active`
DOCKER_COMPOSE_VERSION=`docker-compose --version`
SHERPA_MACHINE_NAME="app1.hw.dnt.no"
HAPROXY_CONTAINER=`docker-compose ps -q haproxy`

# Needed because creating the builder container takes a while
export COMPOSE_HTTP_TIMEOUT=120

if [[ "${DEPLOYMENT_METHOD}" != "soft" && "${DEPLOYMENT_METHOD}" != "hard" ]]; then
  echo "Usage: $0 soft|hard [commit[ branch]]"
  exit 1
fi

if [[ "${DOCKER_MACHINE_ACTIVE}" != "${SHERPA_MACHINE_NAME}" ]]; then
  read -p "Do you want to deploy Sherpa to '${DOCKER_MACHINE_ACTIVE}'? [y/N] " yn
  case $yn in
    [Yy]*) ;;
    *)
      echo "You can set active Docker Host with 'docker-machine env ${SHERPA_MACHINE_NAME}'"
      exit 0;;
  esac
fi

if [[ ! "${DOCKER_COMPOSE_VERSION}" =~ ^docker-compose\ version\ 1.6. ]]; then
  echo "Sorry, ${DOCKER_COMPOSE_VERSION} is not supported!"
  exit 1
fi

if [ -z ${SHERPA_COMMIT} ]; then
  SHERPA_COMMIT=HEAD
fi

if [ -z ${SHERPA_BRANCH} ]; then
  SHERPA_BRANCH=master
fi

echo "Deploying ${SHERPA_BRANCH} to prod with ${DEPLOYMENT_METHOD} migrations..."

# Update submodules in order to know what the currently deployed commit is
git pull
git submodule update --init --recursive

OLD_SHA="`cd sherpa/sherpa; git log -n 1 --pretty=format:'%h' --abbrev-commit`"
if [ -n ${OLD_SHA} ]; then
  OLD_HOST=`docker-compose -f ${COMPOSE_FILE} -p ${OLD_SHA} port www 8080`
  OLD_PORT=`echo ${OLD_HOST} | sed 's/0.0.0.0://'`
  echo "Previous build SHA was ${OLD_SHA}"
fi

# Pull
echo "Updating Sherpa repo..."
(
  cd sherpa/sherpa
  git fetch origin ${SHERPA_BRANCH}
  git reset --hard origin/${SHERPA_BRANCH}
  git pull origin ${SHERPA_BRANCH}
  git reset --hard ${SHERPA_COMMIT}
  git submodule update --init --recursive
)

NEW_SHA="`cd sherpa/sherpa; git log -n 1 --pretty=format:'%h' --abbrev-commit`"
echo "New build SHA is ${NEW_SHA}"

if [[ -n ${OLD_SHA} && "${OLD_SHA}" = "${NEW_SHA}" ]]; then
  echo "You are deploying over the same commit as the previous deployment. This means downtime while building and disabled auto-restore on failure."
  read -p "Really continue? [y/N] " yn
  case $yn in
    [Yy]*) ;;
    *) exit 0;;
  esac
fi

# Build
echo "Building Sherpa containers..."
docker-compose -f ${COMPOSE_FILE} -p ${NEW_SHA} pull
docker-compose -f ${COMPOSE_FILE} -p ${NEW_SHA} build --pull

# Hard deployments: remove the current backend before migrating
if [[ -n ${OLD_SHA} && "$DEPLOYMENT_METHOD" = "hard" ]]; then
  echo "Removing current backend from rotation..."
  docker exec -it ${HAPROXY_CONTAINER} ./route-backend.sh
fi

# Migrate
echo "Running database migrations..."
docker-compose -f ${COMPOSE_FILE} -p ${NEW_SHA} run --rm sherpa ./manage.py migrate

# Check migration status
MIGRATION_STATUS=$?
if [ $MIGRATION_STATUS -ne 0 ]; then
  echo "Migration exited with code $MIGRATION_STATUS; aborting deployment..."

  # Re-add the old deployment backend (if it differs from the new deployment commit)
  if [[ -n ${OLD_SHA} && "${OLD_SHA}" != "${NEW_SHA}" && "$DEPLOYMENT_METHOD" = "hard" ]]; then
    echo "Re-adding the previous deployment backend."
    docker exec -it ${HAPROXY_CONTAINER} ./route-backend.sh ${OLD_PORT}
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
  echo "New builds appears to have no exposed port! Who broke the build?"
  echo "https://youtu.be/DJ001Kgz5wc"

  # Roll back migrations if any
  echo
  read -p "Open a shell to roll back migrations? [y/N] " yn
  case $yn in
    [Yy]*)
      echo "Opening shell; remember that output isn't flushed so the shell might be ready without telling you so."
      docker-compose -f ${COMPOSE_FILE} -p ${NEW_SHA} run --rm sherpa /bin/bash
      ;;
  esac

  # Hard deployments: Re-enable the previous deployment only if the rollback was successful
  # (And if the new deployment SHA differs from the previous)
  if [[ -n ${OLD_SHA} && "${OLD_SHA}" != "${NEW_SHA}" && "$DEPLOYMENT_METHOD" = "hard" ]]; then
    read -p "Re-enable the previous deployment ${OLD_SHA} ? [y/N] " yn
    case $yn in
      [Yy]*) docker exec -it ${HAPROXY_CONTAINER} ./route-backend.sh ${OLD_PORT};;
    esac
  fi

  echo
  docker-compose -f ${COMPOSE_FILE} -p ${NEW_SHA} ps
  echo
  echo "Done, now go clean up your mess."
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
docker exec -it ${HAPROXY_CONTAINER} ./route-backend.sh ${PORT}

# Stop old
if [[ -n ${OLD_SHA} && "${OLD_SHA}" != "${NEW_SHA}" ]]; then
  echo "Stopping old Sherpa containers in 3 seconds..."
  sleep 3
  docker-compose -f ${COMPOSE_FILE} -p ${OLD_SHA} stop

  read -p "Remove old containers, networks and volumes, disabling easy rollback? [y/N] " yn
  case $yn in
    [Yy]*) docker-compose -f ${COMPOSE_FILE} -p ${OLD_SHA} down -v;;
  esac
fi

# Build successful; commit and push the new deployment
git commit -m "Deploy Turistforeningen/sherpa@${NEW_SHA}" sherpa/sherpa
git push
