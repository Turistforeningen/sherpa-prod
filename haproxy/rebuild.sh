#!/bin/bash
PORT=$1

if [ -z ${PORT} ]; then
  echo "usage: $0 [PORT]"
  exit 1
fi

./build.sh
docker stop haproxy
docker rm haproxy
./start.sh
docker exec haproxy ./route-backend.sh ${PORT}

exit 0
