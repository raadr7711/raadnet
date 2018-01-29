#!/bin/sh

in=$1
out=$2

WS_PORT=${WS_PORT:-${HTTPS_PORT}}
PUBLIC_HTTPS_PORT=${PUBLIC_HTTPS_PORT:-${HTTPS_PORT}}

echo "Running fill-template.sh $*"

envsubst '${LOCAL_NETWORK}
${SECURE_LINK_SECRET}
${HTTP_PORT}
${HTTPS_PORT}
${WS_PORT}
${UNMS_HTTP_PORT}
${UNMS_WS_PORT}
${PUBLIC_HTTPS_PORT}' < "${in}" > "${out}"
