#!/usr/bin/env bash
set -o nounset
set -o errexit
set -o pipefail

backupDir="le-node.bak"

cd ~unms/data/cert

if [ -n "$(find "./live" -name "privkey.pem" -exec ls -tR {} +)" ]; then
  # Backup old certificates.
  echo "Archiving old certificates."
  rm -rf "${backupDir}"
  mkdir -p "${backupDir}"
  if [ -e "./accounts" ] ; then mv -f "./accounts" "${backupDir}"; fi
  if [ -e "./archive" ] ; then mv -f "./archive" "${backupDir}"; fi
  if [ -e "./live" ] ; then mv -f "./live" "${backupDir}"; fi
  if [ -e "./renewal" ] ; then mv -f "./renewal" "${backupDir}"; fi

  # Find latest certificate.
  latestCertDir="$(find "${backupDir}/live" -name "privkey.pem" -exec ls -tR {} + | head -1 | xargs dirname)"

  # Update symlinks to point to this certificate.
  echo "Updating symlinks."
  ln -fs "${latestCertDir}/privkey.pem" "live.key"
  ln -fs "${latestCertDir}/fullchain.pem" "live.crt"

  # Restart UNMS for changes to take effect.
  sudo ~unms/app/unms-cli restart

  echo "Done."
else
  echo >&2 "Failed to find private key. Are you using Let's Encrypt?"
  exit 1
fi
