#!/bin/sh
set -o nounset
set -o errexit

SCRIPT_DIR="$( cd "$( dirname "$(readlink -f "$0")")" && pwd )"

# Set defaults values to env variables that are expected to be provided from the container.
export HTTP_PORT="${HTTP_PORT:-80}"
export SUSPEND_PORT="${SUSPEND_PORT:-81}"
export HTTPS_PORT="${HTTPS_PORT:-443}"
export WS_PORT="${WS_PORT:-${HTTPS_PORT}}"
export UNMS_HOST="${UNMS_HOST:-unms}"
export UNMS_HTTP_PORT="${UNMS_HTTP_PORT:-8081}"
export UNMS_WS_PORT="${UNMS_WS_PORT:-8082}"
export UNMS_WS_SHELL_PORT="${UNMS_WS_SHELL_PORT:-8083}"
export UNMS_WS_API_PORT="${UNMS_WS_API_PORT:-8084}"
export UCRM_HOST="${UCRM_HOST:-ucrm}"
export UCRM_HTTP_PORT="${UCRM_HTTP_PORT:-80}"
export UCRM_SUSPEND_PORT="${UCRM_SUSPEND_PORT:-81}"
export PUBLIC_HTTPS_PORT="${PUBLIC_HTTPS_PORT:-${HTTPS_PORT}}"
export WORKER_PROCESSES="${WORKER_PROCESSES:-auto}"
export SECURE_LINK_SECRET="${SECURE_LINK_SECRET:-secret}"

USAGE="Usage:
  refresh-configuration.sh [-h]
                      [--standalone-ucrm --unms-domain UNMS_DOMAIN --ucrm-domain UCRM_DOMAIN]
                      [--standalone-wss]
                      [--main-page unms|ucrm]
                      [--no-reload]
                      [--no-ucrm]

Options:
  -h, --help
    Print this help message and exit.

  --standalone-ucrm
    UCRM will be accessible on a different domain than the UNMS.

  --standalone-wss
    Nginx will expect http and websocket connections to come to different ports based on env
    variables HTTPS_PORT=${HTTPS_PORT} and WS_PORT=${WS_PORT}. Ports must be different.

  --unms-domain UNMS_DOMAIN
    Domain used for UNMS. This option must be specified if --standalone-ucrm is selected.

  --ucrm-domain UCRM_DOMAIN
    Domain used for UCRM. This option must be specified if --standalone-ucrm is selected.

  --main-page unms|ucrm
    What should be displayed on the main page. Default is 'unms'.
    - unms - UNMS login screen.
    - ucrm - UCRM login screen.

  --no-reload
    Do not reload Nginx configuration.

  --no-ucrm
    Disable ucrm.
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
    /usr/sbin/nginx -s reload 2> /dev/null
  fi
}

fillTemplate() {
  local template="$1"
  local target="$2"
  test -f "${template}" || fail "Template file '${template}' does not exist."
  envsubst '
${HTTP_PORT}
${HTTPS_PORT}
${SUSPEND_PORT}
${LOCAL_NETWORK}
${LOGIN_URI}
${PUBLIC_HTTPS_PORT}
${SECURE_LINK_SECRET}
${UNMS_DOMAIN}
${UNMS_HOST}
${UNMS_HTTP_PORT}
${UNMS_WS_PORT}
${UNMS_WS_SHELL_PORT}
${UNMS_WS_API_PORT}
${UCRM_DOMAIN}
${UCRM_HOST}
${UCRM_HTTP_PORT}
${UCRM_SUSPEND_PORT}
${WORKER_PROCESSES}
${WS_PORT}
  ' < "${template}" > "${target}" || fail "Failed to fill template '${template}' to file '${target}'."
}

createConfiguration() {
  # create Nginx config files from templates
  rm -rf "${TARGET_DIR}/conf.d/" || fail "Failed to remove directory '${TARGET_DIR}/conf.d'."
  rm -rf "${TARGET_DIR}/snippets/" || fail "Failed to create directory '${TARGET_DIR}/snippets'."

  mkdir -p "${TARGET_DIR}/conf.d" || fail "Failed to create directory '${TARGET_DIR}/conf.d'."
  mkdir -p "${TARGET_DIR}/snippets" || fail "Failed to create directory '${TARGET_DIR}/snippets'."
  mkdir -p "${TARGET_DIR}/snippets/headers" || fail "Failed to create directory '${TARGET_DIR}/snippets/headers'."

  # Main Nginx configuration file.
  fillTemplate "${TEMPLATES_DIR}/nginx.conf.template" "${TARGET_DIR}/nginx.conf"
  # Nginx API used by UNMS container.
  fillTemplate "${TEMPLATES_DIR}/conf.d/nginx-api.conf.template" "${TARGET_DIR}/conf.d/nginx-api.conf"
  if [ "${ENABLE_UCRM}" = "true" ]; then
    # Suspension page.
    fillTemplate "${TEMPLATES_DIR}/conf.d/ucrm-suspend.conf.template" "${TARGET_DIR}/conf.d/ucrm-suspend.conf"
    # UNMS and UCRM configuration.
    if [ "${STANDALONE_UCRM}" = "true" ] && [ "${STANDALONE_WSS}" = "true" ]; then
      echo "Enabling UNMS https connections on ${UNMS_DOMAIN}:${HTTPS_PORT}"
      fillTemplate "${TEMPLATES_DIR}/conf.d/unms-https.conf.template" "${TARGET_DIR}/conf.d/unms-https.conf"
      echo "Enabling UNMS wss connections on port ${WS_PORT}"
      fillTemplate "${TEMPLATES_DIR}/conf.d/unms-wss.conf.template" "${TARGET_DIR}/conf.d/unms-wss.conf"
      echo "Enabling UCRM https connections on ${UCRM_DOMAIN}:${HTTPS_PORT}, main page redirects to '${LOGIN_URI}'."
      fillTemplate "${TEMPLATES_DIR}/conf.d/ucrm-https.conf.template" "${TARGET_DIR}/conf.d/ucrm-https.conf"
    elif [ "${STANDALONE_UCRM}" = "true" ] && [ "${STANDALONE_WSS}" = "false" ]; then
      echo "Enabling UNMS https and wss connections on ${UNMS_DOMAIN}:${HTTPS_PORT}"
      fillTemplate "${TEMPLATES_DIR}/conf.d/unms-https+wss.conf.template" "${TARGET_DIR}/conf.d/unms-https+wss.conf"
      echo "Enabling UCRM https connections on ${UCRM_DOMAIN}:${HTTPS_PORT}, main page redirects to '${LOGIN_URI}'."
      fillTemplate "${TEMPLATES_DIR}/conf.d/ucrm-https.conf.template" "${TARGET_DIR}/conf.d/ucrm-https.conf"
    elif [ "${STANDALONE_UCRM}" = "false" ] && [ "${STANDALONE_WSS}" = "true" ]; then
      echo "Enabling UNMS and UCRM https connections on port ${HTTPS_PORT}"
      fillTemplate "${TEMPLATES_DIR}/conf.d/unms+ucrm-https.conf.template" "${TARGET_DIR}/conf.d/unms+ucrm-https.conf"
      echo "Enabling UNMS wss connections on port ${WS_PORT}"
      fillTemplate "${TEMPLATES_DIR}/conf.d/unms-wss.conf.template" "${TARGET_DIR}/conf.d/unms-wss.conf"
    else
      echo "Enabling UNMS and UCRM https and wss connections on port ${HTTPS_PORT}, main page redirects to '${LOGIN_URI}'."
      fillTemplate "${TEMPLATES_DIR}/conf.d/unms+ucrm-https+wss.conf.template" "${TARGET_DIR}/conf.d/unms+ucrm-https+wss.conf"
    fi
  else
    UNMS_DOMAIN="\"\""
    if [ "${STANDALONE_WSS}" = "true" ]; then
      echo "Enabling UNMS https connections on port ${HTTPS_PORT}"
      fillTemplate "${TEMPLATES_DIR}/conf.d/unms-https.conf.template" "${TARGET_DIR}/conf.d/unms-https.conf"
      echo "Enabling UNMS wss connections on port ${WS_PORT}"
      fillTemplate "${TEMPLATES_DIR}/conf.d/unms-wss.conf.template" "${TARGET_DIR}/conf.d/unms-wss.conf"
    else
      echo "Enabling UNMS https and wss connections on port ${HTTPS_PORT}"
      fillTemplate "${TEMPLATES_DIR}/conf.d/unms-https+wss.conf.template" "${TARGET_DIR}/conf.d/unms-https+wss.conf"
    fi
  fi
  # Configuration snippets.
  cp "${TEMPLATES_DIR}/snippets/"*.conf "${TARGET_DIR}/snippets/"
  cp "${TEMPLATES_DIR}/snippets/headers/"*.conf "${TARGET_DIR}/snippets/headers/"
}

# Parse arguments.
export STANDALONE_UCRM="false"
export STANDALONE_WSS="false"
export UNMS_DOMAIN=""
export UCRM_DOMAIN=""
export MAIN_PAGE="unms"
export TARGET_DIR="${SCRIPT_DIR}/etc/nginx"
export TEMPLATES_DIR="${SCRIPT_DIR}/templates"
export RELOAD_NGINX="true"
export ENABLE_UCRM="true"
export LOGIN_URI="nms/login" # nms/login | crm/login

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      echo
      echo -e "${USAGE}"
      exit 0
      ;;
    --main-page)
      test "$#" -gt 1 || failWithUsage "Missing parameter for '$1'."
      case "$2" in
        unms) LOGIN_URI="nms/login";;
        ucrm) LOGIN_URI="crm/login";;
        *) failWithUsage "Unknown main page type: '${MAIN_PAGE}'. Expected unms or ucrm."
      esac
      MAIN_PAGE="$2"
      shift
      ;;
    --no-reload)
      RELOAD_NGINX="false"
      ;;
    --no-ucrm)
      ENABLE_UCRM="false"
      ;;
    --standalone-ucrm)
      STANDALONE_UCRM="true"
      ;;
    --standalone-wss)
      STANDALONE_WSS="true"
      ;;
    --unms-domain)
      test "$#" -gt 1 || failWithUsage "Missing parameter for '$1'."
      UNMS_DOMAIN="$2"
      shift
      ;;
    --ucrm-domain)
      test "$#" -gt 1 || failWithUsage "Missing parameter for '$1'."
      UCRM_DOMAIN="$2"
      shift
      ;;
    *)
      # no positional arguments
      failWithUsage "Unexpected argument: '$1'"
      ;;
  esac
  shift
done

# Check arguments.
if [ "${STANDALONE_UCRM}" = "true" ]; then
  test -n "${UNMS_DOMAIN}" || failWithUsage "UNMS domain not specified."
  test -n "${UCRM_DOMAIN}" || failWithUsage "UCRM domain not specified."
  test "${MAIN_PAGE}" != "unms" || failWithUsage "Main page 'ucrm' should be specified for standalone UCRM server."
  test "${ENABLE_UCRM}" != "true" || failWithUsage "UCRM must be enabled for standalone UCRM server."
fi
if [ "${STANDALONE_WSS}" = "true" ]; then
  test "${WS_PORT}" != "${HTTPS_PORT}" || fail "HTTPS_PORT and WS_PORT env variables must be different for --standalone-wss to work."
else
  test "${WS_PORT}" = "${HTTPS_PORT}" || fail "HTTPS_PORT and WS_PORT env variables must be equal if --standalone-wss is not specified."
fi

test -d "${TARGET_DIR}" || fail "Configuration directory '${TARGET_DIR}' does not exist."
test -d "${TEMPLATES_DIR}" || fail "Templates directory '${TEMPLATES_DIR}' does not exist."

# determine local network address
export LOCAL_NETWORK="$(ip route | tail -1 | cut -d' ' -f1)" || fail "Failed to determine local network."
# detect number of cores, make sure that there are at least 2 worker processes
export WORKER_PROCESSES="$(test "$(nproc)" -eq 1 && echo 2 || echo "auto")" || fail "Failed to determine number of worker processes."

createConfiguration || fail "Failed to create Nginx configuration."
reloadNginxConfiguration || fail "Failed to reload Nginx configuration."
