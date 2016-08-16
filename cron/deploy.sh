#!/usr/bin/env bash

# Run from sherpa-prod root
pushd "$(dirname $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) )" > /dev/null

echo "Updating cron/sherpa repo..."
pushd cron/sherpa
git fetch origin
git checkout master
git reset --hard origin/master
git submodule update --init --recursive
popd

echo "Rebuilding Sherpa cron container..."
docker-compose build cron
docker-compose stop cron
docker-compose create cron
docker-compose start cron
