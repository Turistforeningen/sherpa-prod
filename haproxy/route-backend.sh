#!/bin/bash

NEW_PORT=$1
OLD_PORTS=`iptables -t nat -S | grep "\-A PREROUTING" | sed -r 's/^.+ --to-ports ([0-9]+)$/\1/'`

# Add new port to preroute
if [ -n "${NEW_PORT}" ]; then
  echo "Adding backend port '${NEW_PORT}' to prerouting..."
  iptables -t nat -A PREROUTING -p tcp --dport 8000 -j REDIRECT --to-port ${NEW_PORT}
fi

# Remove the old ports
if [ -n "${OLD_PORTS}" ]; then
  while read -r OLD_PORT; do
    echo "Removing old backend port '${OLD_PORT}' from prerouting..."
    iptables -t nat -D PREROUTING -p tcp --dport 8000 -j REDIRECT --to-port ${OLD_PORT}
  done <<< "${OLD_PORTS}"
fi

exit 0
