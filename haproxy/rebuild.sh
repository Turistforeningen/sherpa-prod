#!/bin/bash
PORT=$1
OLD_CONTAINER=`docker-compose ps -q`

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

docker-compose build || exit 1
docker-compose up -d || exit 1
NEW_CONTAINER=`docker-compose ps -q`

echo "Rebuild complete, rerouting backend..."
docker exec ${NEW_CONTAINER} ./route-backend.sh ${PORT}
