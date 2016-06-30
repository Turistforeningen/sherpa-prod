#!/usr/bin/env bash
echo "$(date): Running aws s3 sync"
aws s3 sync --delete s3://turistforeningen s3://turistforeningen-dev
STATUS_CODE=$?
echo "$(date): aws s3 sync exited with status code ${STATUS_CODE}"
