#!/usr/bin/dumb-init /bin/sh

set -e

if [ "$(id -u)" = '0' ]; then
  uid=${FLUENTD_UID:-1000}

  if grep fluent </etc/passwd >/dev/null; then
    deluser fluent
  fi

  adduser -D -g '' -u "${uid}" -h /home/fluent fluent
  chown -R fluent /home/fluent
  chown -R fluent /fluentd

  exec su-exec fluent "$0" "$@"
fi

exec $@
