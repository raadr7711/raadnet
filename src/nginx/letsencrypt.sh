#!/bin/sh

set -e

domain=$1

# don't do anything if user provides a custom certificate
if [ ! -z "${SSL_CERT}" ]; then
  echo "Custom certificate is set up, exiting"
  exit 0
fi

success=false

# don't try to use Let's Encrypt for
# - anything that ends with a digit (cannot be a valid domain name)
# - anything with zero dots (cannot be a valid domain name)
# - anything that contains : (must be an IPv6 address)
if echo "${domain}" | grep "[0-9]$" &>/dev/null \
   || echo "${domain}" | grep "^[^.]*$" &>/dev/null \
   || echo "${domain}" | grep ":" &>/dev/null
then
   echo "Let's Encrypt can only be used for fully qualified domain names."
else
  if [ -f "/cert/use_certbot_staging_env" ]; then
    echo "Using staging environment. The certificate will not be trusted."
    staging="--staging"
  else
    staging=""
  fi
  if certbot certonly \
    ${staging} \
    --quiet \
    --non-interactive \
    --register-unsafely-without-email \
    --keep-until-expiring \
    --agree-tos \
    --webroot \
    --webroot-path "/www" \
    --logs-dir "/tmp" \
    --config-dir "/cert" \
    --work-dir "/tmp" \
    --domain "${domain}"
  then
    success=true
    ln -fs "./live/${domain}/fullchain.pem" "/cert/live.crt"
    ln -fs "./live/${domain}/privkey.pem" "/cert/live.key"

    echo "Reloading Nginx configuration"
    sudo /usr/sbin/nginx -s reload
  fi
fi

if [ "${success}" = true ]; then
  exit 0
else
  exit 1
fi
