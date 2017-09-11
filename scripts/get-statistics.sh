#!/usr/bin/env bash
set -o nounset
set -o errexit
set -o pipefail

deviceId="$1"

if [ -z "${deviceId}" ]; then
  echo "Usage: get-statistics.sh <deviceId>"
  exit 1
fi

docker exec -t unms-redis redis-cli KEYS statistics\* | grep "${deviceId}" | cut -d\" -f2 | xargs -i% sh -c 'sudo docker exec -t unms-redis redis-cli LRANGE % 0 -1 >%.txt'
tar --remove-files -czf statistics.tar.gz statistics*.txt

echo "Statistics saved to statistics.tar.gz"
