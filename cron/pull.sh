#!/bin/bash
pushd /cron/sherpa-prod
git pull
git submodule update sherpa
popd
