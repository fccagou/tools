#!/usr/bin/bash


set -euo pipefail

usage () {
	local cmd
	cmd="${0##*/}"
	cmd="${cmd//-/ }"
    cmd="${cmd%%.sh}"
    cat <<EOF_USAGE
Usage: $cmd [--help|help]"

Affiche l'état de la pki.

EOF_USAGE
}


# Variables de configuration
prefix="$(readlink -f "$(dirname "$0")")"
confloader="$prefix"/pki-config-load.sh
CA_DIR="${CA_DIR:-./myCA}"

if [ "$#" -ge "1" ] && ( [ "$1" == "--help" ] || [ "$1" == "help" ] ); then
	usage
	exit 0
fi

cat <<EOF_HEADER
ca: $(readlink -f "${CA_DIR}")

EOF_HEADER


"$prefix"/pki requests
"$prefix"/pki certs


