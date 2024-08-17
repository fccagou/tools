#!/bin/bash

set -euo pipefail


usage () {
	local cmd
	cmd="${0##*/}"
	cmd="${cmd//-/ }"
    cmd="${cmd%%.sh}"
	cat <<-EOF_USAGE
Usage: $cmd [--help]

Affiche tous les certificats connus de la CA.

EOF_USAGE
}


if [ "$#" -ge "1" ] && [ "$1" == "--help" ]; then
	usage
    exit 0
fi

# Variables de configuration
CA_DIR="${CA_DIR:-./myCA}"

for f in "${CA_DIR}"/newcerts/*.pem;  do
	echo "-------"
	tmp="${f##*/}"
	echo "serial=${tmp%%.pem}"
	openssl x509 -in "$f" -subject -issuer -dates -noout
done

