#!/bin/bash
PORT=$1

if [ -z ${PORT} ]; then
  echo "No port specified, looking up current port in haproxy container..."
  PORT=`docker exec haproxy /bin/bash -c "iptables -t nat -S | grep \"\-A OUTPUT\" | sed -r 's/^.+ --to-destination :([0-9]+)$/\1/'"`
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

./build.sh || exit 1
docker stop haproxy
docker rm haproxy
./start.sh || exit 1
docker exec haproxy ./route-backend.sh ${PORT}

exit 0
