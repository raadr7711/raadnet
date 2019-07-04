#!/bin/sh
set -o nounset
set -o errexit

export WHITELIST_FILE="/etc/nginx/ip-whitelist.conf"

USAGE="Usage:
  set-ip-whitelist.sh [--no-reload] [--whitelist-file FILE] {--show|--clear|--set ADDRESSES}

Options:
  --clear               Allow access to UI from any address.
  --no-reload           Do not reload Nginx configuration.
  --show                Print addresses that are allowed to access UI.
  --set ADDRESSES       Set comma-separated list of addresses or cidrs that are allowed to access UI.
  --whitelist-file FILE File where the whitelist will be stored. Defaults to '${WHITELIST_FILE}'.
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

reloadNginxConfiguration() {
  if [ "${RELOAD_NGINX}" = "true" ] ; then
    sudo /usr/sbin/nginx -s reload 2> /dev/null
  fi
}

setIpAddresses() {
  local whitelist="$1"
  # make sure that the whitelist file exists
  if [ ! -f "${WHITELIST_FILE}" ]; then
    echo "allow all;" > "${WHITELIST_FILE}"
  fi

  rm -f "${TEMP_WHITELIST_FILE}"
  if [ -z "${whitelist}" ]; then
    echo "allow all;" > "${TEMP_WHITELIST_FILE}"
  else
    echo "${whitelist}" | tr ',' '\n' | while read word; do
      echo "allow ${word};" >> "${TEMP_WHITELIST_FILE}"
    done
    echo "deny all;" >> "${TEMP_WHITELIST_FILE}"
  fi

  cp "${WHITELIST_FILE}" "${BACKUP_WHITELIST_FILE}"
  mv "${TEMP_WHITELIST_FILE}" "${WHITELIST_FILE}"

  if /usr/sbin/nginx -t 2> /dev/null; then
    rm "${BACKUP_WHITELIST_FILE}"
  else
    # configuration is invalid, restore previous whitelist file
    mv "${BACKUP_WHITELIST_FILE}" "${WHITELIST_FILE}"
    fail "Invalid Nginx configuration."
  fi
}

clearIpAddresses() {
  echo "allow all;" > "${WHITELIST_FILE}"
}

printIpAddresses() {
  cat "${WHITELIST_FILE}" \
    | grep "allow" \
    | grep -v "allow all" \
    | sed 's/allow[^0-9a-fA-F/:\.]*\([0-9a-fA-F/:\.]*\);/\1/' \
    | tr '\n' ',' \
    | sed 's/,$//'
}

# Parse arguments.
ADDRESSES=""
CLEAR="false"
SHOW="false"
export RELOAD_NGINX="true"
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      echo
      echo -e "${USAGE}"
      exit 0
      ;;
    --clear)
      test "${SHOW}" = "false" || failWithUsage "Cannot use --clear and --show together."
      test -z "${ADDRESSES}" || failWithUsage "Cannot use --clear and --set together."
      CLEAR="true"
      ;;
    --no-reload)
      RELOAD_NGINX="false"
      ;;
    --set)
      test "${SHOW}" = "false" || failWithUsage "Cannot use --set and --show together."
      test "${CLEAR}" = "false" || failWithUsage "Cannot use --set and --clear together."
      test -n "$2" || failWithUsage "Address list cannot be empty. Use --clear to allow connection from any address."
      ADDRESSES="$2"
      shift
      ;;
    --show)
      test "${CLEAR}" = "false" || failWithUsage "Cannot use --show and --clear together."
      test -z "${ADDRESSES}" || failWithUsage "Cannot use --show and --set together."
      SHOW="true"
      ;;
    --whitelist-file)
      test $# -gt 1 || failWithUsage "Missing parameter for '--whitelist-file'."
      WHITELIST_FILE="$2"
      shift
      ;;
  esac
  shift # past argument key
done

TEMP_WHITELIST_FILE="/tmp/ip-whitelist.temp.conf"
BACKUP_WHITELIST_FILE="/tmp/ip-whitelist.backup.conf"

# check arguments
if [ -z "${ADDRESSES}" ] && [ "${CLEAR}" = "false" ] && [ "${SHOW}" = "false" ]; then
  failWithUsage "Please specify one of --show, --clear or --set options."
fi

IPV4_REGEX='^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\/([0-9]|[1-2][0-9]|3[0-2]))?$'
IPV6_REGEX='^((([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])))(\/([0-9]{1,2}|1[0-1][0-9]|12[0-8]))?$'

if [ -n "${ADDRESSES}" ]; then
  if echo "${ADDRESSES}" | grep -Eq "^[][0-9a-fA-F\/\.:,]*$"; then
    echo "${ADDRESSES}" | tr ',' '\n' | while read word; do
      if echo "${word}" | grep -Eq "${IPV4_REGEX}"; then
        continue
      else if echo "${word}" | grep -Eq "${IPV6_REGEX}"; then
        continue
      else
        fail "Invalid IP address: '${word}'"
      fi
      fi
    done
  else
    fail "Invalid address list. IP address list can only contain numbers, letters a-f, slashes ('/'), dots ('.'), colons (':') and commas (',')."
  fi
fi

if [ "${SHOW}" = "true" ]; then
  printIpAddresses
else if [ "${CLEAR}" = "true" ]; then
  clearIpAddresses
  reloadNginxConfiguration
else
  setIpAddresses "${ADDRESSES}"
  reloadNginxConfiguration
fi
fi
