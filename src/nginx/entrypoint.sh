#!/usr/bin/dumb-init /bin/sh

set -e

echo "Running entrypoint.sh"
uid=${NGINX_UID:-1000}

# do this only once after creating the container
if ! id -u unms >/dev/null 2>&1; then

  # create unms user that will own nginx
  echo "Creating user unms with UID ${uid}"
  adduser -D -u "${uid}" unms

  # create directory for LetsEncrypt acme-challenge
  echo "Creating /www directory"
  mkdir -p /www
  chown unms /www

  echo "Creating nginx configuration"
  WS_PORT="${WS_PORT:-${HTTPS_PORT}}"
  if [ "${WS_PORT}" = "${HTTPS_PORT}" ]; then
    /refresh-configuration.sh --no-reload --no-ucrm
  else
    /refresh-configuration.sh --no-reload --standalone-wss --no-ucrm
  fi

  if [ -n "${UNMS_IP_WHITELIST}" ]; then
    /ip-whitelist.sh --no-reload --set "${UNMS_IP_WHITELIST}"
  else
    /ip-whitelist.sh --no-reload --clear
  fi

  # Archive the Let's Encrypt directories if they are using the old format.
  # UNMS with integrated nginx is using certbot to issue Let's Encrypt certificates.
  # In previous versions we were using a node module that had different
  # format of config files and slightly different directory structure than certbot.
  migrationNeeded="false"
  if [ -d "/cert/renewal" ] ; then
    for configFile in /cert/renewal/*.conf; do
      # We need to determine whether we are using the old format or the new format.
      # In the old format the cert renewal config files contained duplicate
      # lines. Check the renewal folder and if there is a config file with
      # duplicate lines then assume that we are using the old format.
      if [ ! -z "$(sort ${configFile} | uniq -d)" ]; then
        migrationNeeded="true"
        break
      fi;
    done
  fi
  if [ "${migrationNeeded}" = "true" ] ; then
    backupDir="/cert/le-node.bak"
    echo "Backing up incompatible Node Let's Encrypt files to '${backupDir}'"
    mkdir -p "${backupDir}"
    echo "Backup of incompatible Node Let's Encrypt files." > "${backupDir}/README"

    if [ -e "/cert/accounts" ] ; then mv -f "/cert/accounts" "${backupDir}"; fi
    if [ -e "/cert/archive" ] ; then mv -f "/cert/archive" "${backupDir}"; fi
    if [ -e "/cert/live" ] ; then mv -f "/cert/live" "${backupDir}"; fi
    if [ -e "/cert/renewal" ] ; then mv -f "/cert/renewal" "${backupDir}"; fi

    if [ -z "${SSL_CERT}" ]; then
      echo "Updating symlinks."
      # We need to update live.key and live.crt symlinks, if they exist and if
      # they point inside the /cert/live directory.
      # Find last modified private key in /cert/live folder and assume that it is
      # the latest valid key.
      # We cannot assume that it is the key in live/DOMAIN/privkey.pem because due
      # to the incomatibility with previous version this key was not recognized by
      # certbot in UNMS 0.11.0 and migth have been replaced with live/DOMANI-0001/privkey.pem
      oldCertDir="$(cd "/cert" && find "./le-node.bak/live" -name "privkey.pem" -exec ls -tR {} + | head -1 | xargs dirname)"
      echo "${oldCertDir}"
      keyFile="/cert/live.key"
      certFile="/cert/live.crt"
      if [ -L "${keyFile}" ] && readlink "${keyFile}" | grep -q "^live\|^\./live" ; then
        echo "Changing '${keyFile}' symlink to point to '${oldCertDir}/privkey.pem' ";
        ln -fs "${oldCertDir}/privkey.pem" "${keyFile}"
      fi
      if [ -L "${certFile}" ] && readlink "${certFile}" | grep -q "^live\|^\./live" ; then
        echo "Changing '${certFile}' symlink to point to '${oldCertDir}/fullchain.pem' ";
        ln -fs "${oldCertDir}/fullchain.pem" "${certFile}"
      fi
    fi
  fi

  # If a self signed certificate exists from UNMS versins without integrated nginx, reuse it. This is necessary,
  # because UNMS UI will report an update failure if the certificate changes after the update.
  # This requires determining the Common Name and renaming the certificate files.
  if [ -z "${SSL_CERT}" ] && [ -f "/cert/self-signed.crt" ] && [ -f "/cert/self-signed.key" ]; then
    echo "Found old certificate files, extracting Common Name..."
    commonName=$(openssl x509 -noout -subject -in /cert/self-signed.crt 2>/dev/null | sed -n '/^subject/s/^.*CN=//p' || true)
    if [ ! -z "${commonName}" ]; then
      echo "Renaming old certificate files from 'self-signed' to '${commonName}'"
      mv -f "/cert/self-signed.crt" "/cert/${commonName}.crt" || echo "Failed to rename self-signed.crt to ${commonName}.crt"
      mv -f "/cert/self-signed.key" "/cert/${commonName}.key" || echo "Failed to rename self-signed.key to ${commonName}.key"
    else
      echo "Failed to extract Common Name from old certificate file, will not reuse"
    fi
  fi

fi

# generate self-signed SSL certificate if none is provided or existing
if [ -e /cert/live.crt ] && [ -e /cert/live.key ]; then
  echo "Will use existing SSL certificate"
else
  if [ -z "${SSL_CERT}" ]; then
    sudo --preserve-env -u unms /refresh-certificate.sh --self-signed localhost --no-reload
  else
    sudo --preserve-env -u unms /refresh-certificate.sh --custom localhost --no-reload
  fi
fi

echo "Entrypoint finished"
echo "Calling exec $*"
exec "$@"
