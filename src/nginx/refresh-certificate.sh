#!/bin/sh
set -o nounset
set -o errexit

USAGE="Usage:
  refresh-certificate.sh [-h] --custom|--lets-encrypt|--self-signed DOMAIN
                      [--target-dir DIR] [--custom-cert-dir DIR] [--no-reload]

Arguments:
  DOMAIN            Domain name for which to generate certificate.

Options:
  -h, --help        Print this help message and exit.
  --custom          Use custom certificate specified in SSL_CERT, SSL_CERT_KEY and optional SSL_CERT_CA
                    environment variables. File paths are relative to --custom-cert-dir
  --custom-cert-dir Directory where the custom certificate is stored. Directory must exist. '/usercert' is
                    used by default.
  --lets-encrypt    Use Let's Encrypt certificate.
  --no-reload       Do not reload Nginx configuration.
  --self-signed     Use self-signed certificate.
  --target-dir      Directory where to generate certificate. Directory must exist. '/cert' is used by default.
"

# Log given message and exit with code 1.
fail() {
  echo >&2 "$1"
  exit 1
}

# Print given message and the usage and exit with code 1.
failWithUsage() {
  echo -e "Error: $1" >&2
  echo
  echo -e "${USAGE}" >&2
  exit 1
}

# Fallback solution. If there is no certificate or just the default certificate for localhost generate a self-signed
# certificate for the domain and use it.
# Keep any other certificate even if it is for a wrong domain. We do not want to switch to self-signed
# certificate if there is some problem. Instead the user should correct the issue.
fallback() {
  echo "$1" >&2
  # Make sure that a fallback self-signed certificate exists for the domain.
  if [ ! -f "${TARGET_CERT_FILE}" ] || [ ! -f "${TARGET_KEY_FILE}" ] ; then
    # Certificate is missing.
    echo "No certificate found."
    generateSelfSignedCert || true
  else
    subject=$(openssl x509 -noout -subject -in "${TARGET_CERT_FILE}" | sed 's/.*=[[:space:]]*//' || true)
    if [ "${subject}" = "localhost" ] ; then
      # There is only the default certificate without domain.
      echo "Found default certificate for 'localhost'."
      generateSelfSignedCert || true
    else
      echo "Keeping existing certificate for '${subject}'."
    fi
  fi
  exit 1
}

reloadNginxConfiguration() {
  if [ "${RELOAD_NGINX}" = "true" ] ; then
    sudo /usr/sbin/nginx -s reload 2> /dev/null
  fi
}

generateSelfSignedCert() {
  local cert="${CERT_DIR}/${DOMAIN}.crt"
  local key="${CERT_DIR}/${DOMAIN}.key"
  if [ ! -f "${cert}" ]|| [ ! -f "${key}" ] || ! openssl x509 -checkend 86400 -noout -in "${cert}"; then
    echo "Generating self-signed certificate for '${DOMAIN}'."
    # determine subjectAltName - IP addresses need both IP and DNS, domains just need DNS
    export SAN # variable is used in openssl.cnf
    case "${DOMAIN}" in
      *:*)    SAN="IP:${DOMAIN},DNS:${DOMAIN}" ;; # contains ":" - IPv6 address
      *[0-9]) SAN="IP:${DOMAIN},DNS:${DOMAIN}" ;; # ends with a digit - IPv4 address
      *)      SAN="DNS:${DOMAIN}" ;;              # else domain name
    esac
    openssl req -nodes -x509 -newkey rsa:4096 -subj "/CN=${DOMAIN}" -keyout "${key}" -out "${cert}" -days "36500" -batch -config "/openssl.cnf" 2> /dev/null || fail "Failed to generate self-signed certificate for '${DOMAIN}'"
    chmod 600 "${key}"
    chmod 600 "${cert}"
  fi

  ln -fs "./${DOMAIN}.crt" "${TARGET_CERT_FILE}"
  ln -fs "./${DOMAIN}.key" "${TARGET_KEY_FILE}"
  reloadNginxConfiguration
}

# Use certificate that user specified during installation. We need to create a copy to join certificate and chain
# into one file.
generateCustomCert() {
  local cert="${CERT_DIR}/custom.crt"
  local key="${CERT_DIR}/custom.key"
  test -n "${SSL_CERT}" || fallback "Custom certificate is not defined."
  test -n "${SSL_CERT_KEY}" || fallback "Custom key is not defined."

  local keyFileChanged="true"
  local tmpKey="/tmp/custom.key"
  touch "${tmpKey}"
  chmod 600 "${tmpKey}"
  sudo /bin/cat "${CUSTOM_CERT_DIR}/${SSL_CERT_KEY}" > "${tmpKey}" || fallback "Failed to create temp key from '${CUSTOM_CERT_DIR}/${SSL_CERT_KEY}'."
  if [ -f "${key}" ] &&
    diff "${tmpKey}" "${key}" > /dev/null ;
  then
    keyFileChanged="false"
  fi

  local certFileChanged="true"
  local tmpCert="/tmp/custom.crt"
  touch "${tmpKey}"
  chmod 600 "${tmpKey}"
  if [ -z "${SSL_CERT_CA}" ]; then sudo /bin/cat "${CUSTOM_CERT_DIR}/${SSL_CERT}" > "${tmpCert}" || fallback "Failed to create temp certificate from '${CUSTOM_CERT_DIR}/${SSL_CERT}'."
  else sudo /bin/cat "${CUSTOM_CERT_DIR}/${SSL_CERT}" "${CUSTOM_CERT_DIR}/${SSL_CERT_CA}" > "${tmpCert}" || fallback "Failed to create temp certificate and chain from '${CUSTOM_CERT_DIR}/${SSL_CERT}' and '${CUSTOM_CERT_DIR}/${SSL_CERT_CA}'."
  fi
  if [ -f "${cert}" ] &&
    diff "${tmpCert}" "${cert}" > /dev/null
  then
    certFileChanged="false"
  fi

  if [ "${keyFileChanged}" = "true" ] || [ "${certFileChanged}" = "true" ] ; then
    # Nginx needs certificate and chain in one file. Make a copy of key file and join certificate and chain into
    # one file.
    echo "Updating custom certificate."
    # Copy key file.
    mv "${tmpKey}" "${key}" || fallback "Failed to copy key."
    mv "${tmpCert}" "${cert}" || fallback "Failed to copy key."
  else
    echo "Custom certificate not changed."
  fi

  ln -fs "./custom.crt" "${TARGET_CERT_FILE}"
  ln -fs "./custom.key" "${TARGET_KEY_FILE}"
  reloadNginxConfiguration
}

generateLetsEncryptCert() {
  # don't try to use Let's Encrypt for
  # - anything that ends with a digit (cannot be a valid domain name)
  # - anything with zero dots (cannot be a valid domain name)
  # - anything that contains : (must be an IPv6 address)
  if echo "${DOMAIN}" | grep "[0-9]$" &>/dev/null \
     || echo "${DOMAIN}" | grep "^[^.]*$" &>/dev/null \
     || echo "${DOMAIN}" | grep ":" &>/dev/null
  then
     fallback "Let's Encrypt can only be used for fully qualified domain names."
  fi

  if [ -f "${CERT_DIR}/use_certbot_staging_env" ]; then
    echo "Using staging environment. The certificate will not be trusted."
    staging="--staging"
  else
    staging=""
  fi

  certbot certonly \
    ${staging} \
    --quiet \
    --non-interactive \
    --register-unsafely-without-email \
    --keep-until-expiring \
    --agree-tos \
    --webroot \
    --webroot-path "/www" \
    --logs-dir "/tmp" \
    --config-dir "${CERT_DIR}" \
    --work-dir "/tmp" \
    --domain "${DOMAIN}" || fallback "Failed to generate or update Let's Encrypt certificate."

  lowercaseDomain=$(echo "${DOMAIN}" | tr '[:upper:]' '[:lower:]')
  ln -fs "./live/${lowercaseDomain}/fullchain.pem" "${TARGET_CERT_FILE}"
  ln -fs "./live/${lowercaseDomain}/privkey.pem" "${TARGET_KEY_FILE}"
  reloadNginxConfiguration
}

# Parse arguments.
export DOMAIN=""
export CERT_TYPE=""
export CERT_DIR="/cert"
export CUSTOM_CERT_DIR="/usercert"
export RELOAD_NGINX="true"
while [ $# -gt 0 ]; do
  key="$1"
  case $key in
    -h|--help)
      echo
      echo -e "${USAGE}"
      exit 0
      ;;
    --custom)
      test -z "${CERT_TYPE}" || failWithUsage "Requested 'custom' certificate but '${CERT_TYPE}' was requested earlier."
      CERT_TYPE="custom"
      ;;
    --custom-cert-dir)
      test $# -gt 1 || failWithUsage "Missing parameter for '--custom-cert-dir'."
      CUSTOM_CERT_DIR="$2"
      shift
      ;;
    --lets-encrypt)
      test -z "${CERT_TYPE}" || failWithUsage "Requested 'lets-encrypt' certificate but '${CERT_TYPE}' was requested earlier."
      CERT_TYPE="lets-encrypt"
      ;;
    --no-reload)
      RELOAD_NGINX="false"
      ;;
    --self-signed)
      test -z "${CERT_TYPE}" || failWithUsage "Requested 'self-signed' certificate but '${CERT_TYPE}' was requested earlier."
      CERT_TYPE="self-signed"
      ;;
    --target-dir)
      test $# -gt 1 || failWithUsage "Missing parameter for '--target-dir'."
      CERT_DIR="$2"
      shift
      ;;
    *)
      test -z "${DOMAIN}" || failWithUsage "Unexpected argument: '$1'"
      # first positional argument is the DOMAIN
      DOMAIN="$1"
      ;;
  esac
  shift # past argument key
done

# Check arguments.
test -n "${DOMAIN}" || fail "Domain not specified."
test -n "${CERT_TYPE}" || fail "No certificate type specified".
test -d "${CERT_DIR}" || fail "Certificate directory '${CERT_DIR}' does not exist."

export TARGET_CERT_FILE="${CERT_DIR}/live.crt"
export TARGET_KEY_FILE="${CERT_DIR}/live.key"
export SSL_CERT="${SSL_CERT:-}"
export SSL_CERT_KEY="${SSL_CERT_KEY:-}"
export SSL_CERT_CA="${SSL_CERT_CA:-}"

case "${CERT_TYPE}" in
  self-signed) generateSelfSignedCert ;;
  custom) generateCustomCert ;;
  lets-encrypt) generateLetsEncryptCert ;;
  *) fallback "Unknown certificate type '${CERT_TYPE}'." ;;
esac
