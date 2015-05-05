#!/bin/bash
docker run -d \
  --name=haproxy \
  --restart=always \
  --add-host docker0:172.17.42.1 \
  -p 0.0.0.0:80:80 \
  -p 0.0.0.0:443:443 \
  sherpa/haproxy
