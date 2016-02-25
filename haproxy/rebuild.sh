#!/bin/bash

# Run from sherpa-prod root
pushd "$(dirname $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) )" > /dev/null

PORT=$1
OLD_CONTAINER=`docker-compose ps -q haproxy`
if [ -z ${PORT} ]; then
  echo "No port specified, looking up current port in haproxy container..."
  PORT=`docker exec ${OLD_CONTAINER} /bin/bash -c "iptables -t nat -S | grep \"\-A OUTPUT\" | sed -r 's/^.+ --to-destination :([0-9]+)$/\1/'"`
  read -p "Rebuilding with backend route to port '${PORT}', OK? [y/N] " yn
  case $yn in
    [Yy]*)
      ;;
    *)
      echo "usage: $0 [PORT]"
      exit 1
      ;;
  esac
fi

docker-compose build haproxy || exit 1
docker-compose up -d haproxy || exit 1
NEW_CONTAINER=`docker-compose ps -q haproxy`

echo "Rebuild complete, rerouting backend..."
docker exec ${NEW_CONTAINER} ./route-backend.sh ${PORT}

popd > /dev/null
