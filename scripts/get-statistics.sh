#!/usr/bin/env bash
set -o nounset
set -o errexit
set -o pipefail

outdir=~unms/device-statistics
outfile=~unms/device-statistics.tar.gz

if [ -z "$1" ]; then
  echo "Usage: get-statistics.sh <deviceId>"
  exit 1
fi

deviceId="$1"

mkdir -p "${outdir}"
keys=( $(docker exec -t unms-redis redis-cli KEYS statistics\* | grep "${deviceId}" | cut -d\" -f2) )

for key in "${keys[@]}"; do
  docker exec -t unms-redis redis-cli LRANGE "${key}" 0 -1 >${outdir}/${key}
done

tar --remove-files -C "${outdir}" -czf "${outfile}" .

echo "Saved to ${outfile}"