#!/bin/bash
docker run -d -p 0.0.0.0:80:80 -p 0.0.0.0:443:443 --name=haproxy --restart=always sherpa/haproxy
