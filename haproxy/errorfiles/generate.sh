#!/bin/bash

# This script generates `50x.html` pages based on the `TEMPLATE`.

declare -a errors=(
  "504 Gateway Time-out"
  "503 Service Unavailable"
  "502 Bad Gateway"
  "500 Server Error"
)

B64_IMAGE=`base64 turbo.jpg`

for error in "${errors[@]}"; do
  code=`echo ${error} | head -n1 | awk '{print $1;}'`
  cp TEMPLATE "${code}.html"
  sed -i '' "s/{{ ERROR_HTTP_STATUS }}/${error}/g" "${code}.html"
  sed -i '' "s@{{ ERROR_B64_IMAGE }}@${B64_IMAGE}@g" "${code}.html"
done
