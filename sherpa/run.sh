#!/bin/bash

SHA=62bc4e9
PORT=8000

docker run --name static_${SHA} sherpa/static:${SHA} /bin/echo

docker run -d --restart=always --name memcached_${SHA} memcached:1.4
docker run -d --restart=always --name django_${SHA} --link
memcached_${SHA}:memcached sherpa/django:${SHA}
docker run -d --restart=always --name nginx_${SHA} \
  --publish ${PORT}:8080 \
  --link django_${SHA}:sherpa \
  --volumes-from static_${SHA} \
  sherpa/nginx:${SHA}
