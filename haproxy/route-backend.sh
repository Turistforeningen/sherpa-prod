#!/bin/bash

NEW_PORT=$1
OLD_PORTS=`iptables -t nat -S | grep "\-A OUTPUT" | sed -r 's/^.+ --to-destination :([0-9]+)$/\1/'`

# Add new port to preroute
if [ -n "${NEW_PORT}" ]; then
  echo "Adding backend port '${NEW_PORT}' to NAT redirects..."
  iptables -t nat -A OUTPUT -p tcp --dport 8080 -j DNAT --to-destination :${NEW_PORT}
fi

# Remove the old ports
if [ -n "${OLD_PORTS}" ]; then
  while read -r OLD_PORT; do
    echo "Removing old backend port '${OLD_PORT}' from NAT redirects..."
    iptables -t nat -D OUTPUT -p tcp --dport 8080 -j DNAT --to-destination :${OLD_PORT}
  done <<< "${OLD_PORTS}"
fi

exit 0
