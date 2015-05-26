#!/bin/bash

WATCH_INTERVAL=0.2
WATCH_PATH=doge/

for arg; do
  if [[ "${arg}" == "--help" || "${arg}" == "-h" ]]; then
    cat << EOF
Usage: $0 [OPTIONS]

Simple utility to watch dnt.no when deploying new changes.

Options:
  -h, --help=false      Print usage
  --interval=0.2        Test interval
  --path=doge/          Test path
EOF
    exit 0
  fi

  if [[ "${arg}" == "--interval" ]]; then
    arg_prev=WATCH_INTERVAL
  fi

  if [[ "${arg_prev}" == "WATCH_INTERVAL" ]]; then
    WATCH_INTERVAL=${arg}
  fi

  if [[ "${arg}" == "--path" ]]; then
    arg_prev=WATCH_PATH
  fi

  if [[ "${arg_prev}" == "WATCH_PATH" ]]; then
    WATCH_PATH=${arg}
  fi
done

while [[ true ]]; do
  echo "$(date)  | $(curl -sI https://www.dnt.no/${WATCH_PATH} | grep HTTP)";
  sleep ${WATCH_INTERVAL};
done
