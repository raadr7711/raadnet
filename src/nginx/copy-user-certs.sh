#!/bin/sh

# Check timestamps of user certificate files and if they are newer than the
# certificates in /cert copy them over.
# Join cert and ca if necessary.

set -e
set -u

CERT_FILE="/cert/live.crt"
KEY_FILE="/cert/live.key"

is_key_or_cert_changed() {
  # The cert and key may be symlinks.
  if ! [ -f "${CERT_FILE}" ]; then return 0; fi
  if ! [ -f "${KEY_FILE}" ]; then return 0; fi

  if ! [ "${CERT_FILE}" -ot "$(realpath /usercert/${SSL_CERT})" ] \
      && ! [ "${KEY_FILE}" -ot "$(realpath /usercert/${SSL_CERT_KEY})" ] \
      && ([ -z "${SSL_CERT_CA}" ] || ! [ "${CERT_FILE}" -ot "$(realpath /usercert/${SSL_CERT_CA})" ]);
    then
    return 1
  fi
  return 0
}

copy_key_and_cert() {
  rm -f "${CERT_FILE}" "${KEY_FILE}"
  cat "/usercert/${SSL_CERT_KEY}" > /cert/live.key
  if [ -z "${SSL_CERT_CA}" ]; then
    cat "/usercert/${SSL_CERT}" > /cert/live.crt
  else
    # Unlike previous nodejs implementation, nginx needs certificate and chain
    # in one file.
    echo "Joining '/usercert/${SSL_CERT}' and '/usercert/${SSL_CERT_CA}' into '/cert/live.crt'"
    cat "/usercert/${SSL_CERT}" "/usercert/${SSL_CERT_CA}" > /cert/live.crt
  fi
}

if is_key_or_cert_changed; then
  echo "User certificate changed."
  copy_key_and_cert
  if [ "$#" -eq 1 ] && [ "$1" = "reload" ]; then
    echo "Reloading Nginx configuration"
    nginx -s reload
  fi
else
  echo "User certificate not changed."
fi
