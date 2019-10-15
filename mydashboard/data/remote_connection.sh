#!/bin/sh

SITE="${1}"
DOMAIN="${2}"
GROUP="${3}"
REMOTE_HOST="${4}"

cat - > /tmp/mydashboard_remote.log <<EOF_REMOTE
Accessing to ${SITE}/${DOMAIN}/${GROUP}/${REMOTE_HOST}

This is a sample script for test purpose.
Make your own script. The remote connection can be different
depending on SITE, DOMAIN and GROUP parameters.

EOF_REMOTE

