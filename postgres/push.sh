#!/bin/bash

# Log in Docker Hub / Docker Registry
docker login

# turistforeningen/sherpa-postgres
docker build --pull -t turistforeningen/sherpa-postgres:latest .
docker push turistforeningen/sherpa-postgres:latest

# turistforeningen/sherpa-postgres-psql
docker build --pull -t turistforeningen/sherpa-postgres-psql:latest psql/
docker push turistforeningen/sherpa-postgres-psql:latest
