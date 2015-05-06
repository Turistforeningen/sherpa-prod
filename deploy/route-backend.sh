#!/bin/bash

PORT=$1
PORTFILE='portfile'
PORT_REGEX='^([0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$'

if ! [[ $PORT =~ $PORT_REGEX ]] ; then
   echo "error: Invalid port number '$PORT'" >&2
   exit 1
fi

# Add new port to preroute
echo "Adding backend port '$PORT' to prerouting..."
iptables -t nat -A PREROUTING -p tcp --dport 8000 -j REDIRECT --to-port $PORT

# Remove existing prerouted port
if [ -e $PORTFILE ]; then
    OLD_PORT=$(cat $PORTFILE)
    echo "Removing old backend port '$OLD_PORT' from prerouting..."
    iptables -t nat -D PREROUTING -p tcp --dport 8000 -j REDIRECT --to-port $OLD_PORT
fi

# Save the newly routed port to the portfile
echo $PORT > $PORTFILE
