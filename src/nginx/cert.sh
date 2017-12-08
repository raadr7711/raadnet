#!/bin/sh

set -e

echo "Running cert.sh $*"
domain=$1

# don't do anything if user provides a custom certificate
if [ ! -z "${SSL_CERT}" ]; then
  echo "Custom certificate is set up, exiting"
  exit 0
fi

# domain name is required
if [ -z "${domain}" ]; then
  echo "No domain specified, exiting"
  exit 1
fi

echo "Looking for an existing self-signed certificate for ${domain}"

if [ -f "/cert/${domain}.crt" ] && [ -f "/cert/${domain}.key" ]; then
  echo "Found existing self-signed certificate for ${domain}"
else
  echo "Generating self-signed certificate for ${domain}"

  # determine subjectAltName - IP addressess need both IP and DNS, domains just need DNS
  case "${domain}" in
    *:*)    SAN="IP:${domain},DNS:${domain}" ;; # contains ":" - IPv6 address
    *[0-9]) SAN="IP:${domain},DNS:${domain}" ;; # ends with a digit - IPv4 address
    *)      SAN="DNS:${domain}" ;;              # else domain name
  esac

  SAN="${SAN}" openssl req -nodes -x509 -newkey rsa:4096 -subj "/CN=${domain}" -keyout "/cert/${domain}.key" -out "/cert/${domain}.crt" -days "36500" -batch -config "openssl.cnf"
fi
ln -fs "./${domain}.crt" "/cert/live.crt"
ln -fs "./${domain}.key" "/cert/live.key"

echo "Reloading Nginx configuration"
sudo /usr/sbin/nginx -s reload

echo "cert.sh ${domain} finished successfully"
