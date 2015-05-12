#!/bin/bash
cd /cron/sherpa-prod
FULL_SHA=$(git submodule status sherpa | awk '{ print $1 }' | sed 's/^-//')
echo ${FULL_SHA::7}