#!/bin/bash

docker build -t sherpa/django:62bc4e9 -f sherpa/Dockerfile sherpa/
docker build -t sherpa/static:62bc4e9 -f sherpa/static/Dockerfile.static sherpa/static/
docker build -t sherpa/nginx:62bc4e9  -f sherpa/Dockerfile.nginx sherpa/build/
