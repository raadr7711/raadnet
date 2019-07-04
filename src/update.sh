#!/usr/bin/env bash
set -o nounset
set -o errexit
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONTROL_DIR="$(realpath "${SCRIPT_DIR}/../data/control")"
ARGUMENTS_FILE="${CONTROL_DIR}/arguments"
LOCK_DIR="${CONTROL_DIR}/arguments.lock"
LAST_RUN_LOG_FILE="${CONTROL_DIR}/last-run.log"
LAST_RUN_FILE="${CONTROL_DIR}/last-run.timestamp"
UNMS_CLI="${SCRIPT_DIR}/unms-cli"
LOCKED="false"
CRON="false"
DEBUG="false"

USAGE="Usage:
  update.sh [-h] [--cron] [--debug]

Executes '${UNMS_CLI}' with arguments parsed from file '${ARGUMENTS_FILE}'.

This script is executed by cron job or by systemd. It should not be run manually except
for debugging purposes. Use the 'unms-cli' insetead.

    --cron      Command output will be redirected to file ${CONTROL_DIR}/command-*.log
                Other output will be redirected to ${LAST_RUN_LOG_FILE}.
    --debug     Print additional debug messages.
    -h, --help  Print usage and exit.
"

# Log given message and exit with code 1.
fail() {
  error "Error: $1"
  exit 1
}

# Print given message and the usage and exit with code 1.
failWithUsage() {
  error "Error: $1"
  echo
  echo -e "${USAGE}" >&2
  exit 1
}

# Log given message to stderr or to log file.
error() {
  if [ "${CRON}" = "true" ] && [ "${LOCKED}" = "true" ]; then
    echo -e "$1" >> "${LAST_RUN_LOG_FILE}"
  else
    echo -e "$1" >&2
  fi
}

# If running in debug mode then log given message to stdout or to log file. Otherwise do nothing.
debug() {
  if [ "${DEBUG}" = "true" ]; then
    if [ "${CRON}" = "true" ]; then
      # Ignore message if not holding the lock to prevent writing to other processe's log file.
      if [ "${LOCKED}" = "true" ]; then
        echo -e "$1" >> "${LAST_RUN_LOG_FILE}"
      fi
    else
      echo -e "$1"
    fi
  fi
}

# Create lock directory or exit if the directory already exists.
lockOrExit() {
  if ! mkdir "${LOCK_DIR}" 2>/dev/null; then
    debug "Lock already exists, another process is running."
    exit 0
  fi
  trap unlock EXIT # To make sure that the lock file will be deleted.
  rm -f "${LAST_RUN_LOG_FILE}"
  LOCKED="true"
  debug "Locked"
}

# Remove the lock directory.
unlock() {
  debug "Unlocked"
  LOCKED="false"
  rmdir "${LOCK_DIR}" || true
}

runCommand() {
  if [ ! -f "${ARGUMENTS_FILE}" ]; then
    debug "File '${ARGUMENTS_FILE}' not found. Nothing to do."
    return 0
  fi

  local arguments=()
  # Read argumetnts from file.
  mapfile -n 10 -t arguments < "${ARGUMENTS_FILE}" # mapfile requires bash version 4 or greater
  rm -f "${ARGUMENTS_FILE}"

  # Whitelist of allowed commands.
  local command="${arguments[0]}"
  case "${command}" in
    update);;
    clear-conntrack);;
    *)
      fail "Command '${command}' is not supported."
      ;;
  esac


  debug "Running 'unms-cli ${arguments[*]}'."
  if [ "${CRON}" = "true" ]; then
    # If running from cron redirect command output to file.
    local logFile="${CONTROL_DIR}/command-${command}.log"
    echo "$(date): Running 'unms-cli ${arguments[*]}'." > "${logFile}" 2>&1
    if "${UNMS_CLI}" "${arguments[@]}" >> "${logFile}" 2>&1; then
      echo "$(date): Command 'unms-cli ${arguments[*]}' finished." >> "${logFile}" 2>&1
    else
      echo "$(date): Command 'unms-cli ${arguments[*]}' failed." >> "${logFile}" 2>&1
      exit 1
    fi
  else
    "${UNMS_CLI}" "${arguments[@]}" || fail "Command 'unms-cli ${arguments[*]}' failed."
    echo "Command 'unms-cli ${arguments[*]}' finished."
  fi
}

if [ "${EUID}" = 0 ]; then
  fail "Refusing to run as root to prevent creation of root-owned files."
fi

# Update the timestamp when this script last run.
mkdir -p "${CONTROL_DIR}"
date +%s > "${LAST_RUN_FILE}"

# Parse arguments.
export COMMAND=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      echo
      echo -e "${USAGE}"
      exit 0
      ;;
    --cron) CRON="true" ;;
    --debug) DEBUG="true" ;;
    *) failWithUsage "Unexpected argument: '$1'" ;;
  esac
  shift
done

lockOrExit
runCommand
