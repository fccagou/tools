#!/bin/bash
set -euo pipefail

usage () {
	local cmd
	cmd="${0##*/}"
	cmd="${cmd//-/ }"
    cmd="${cmd%%.sh}"
	cat <<-EOF_USAGE
Usage: $cmd [--help]

Affiche les données de configuration de la pki.

EOF_USAGE
}


# Variables de configuration
prefix="$(dirname "$(readlink -f "$0")")"

CA_DIR="${CA_DIR:-./myCA}"
CONFIG_FILE="${CA_DIR}/openssl.cnf"

[ "$#" -ge "1" ] && [ "$1" == "--help" ] && {
	usage
    exit 1
} || :


[ -f "${CONFIG_FILE}" ] || {
    echo "Erreur, fichier de configuration ${CONFIG_FILE} inconnu." >&2
    exit 1
}

. "$prefix"/pki-config-load.sh

for e in "${!pki_config[@]}"; do
    echo "$e=${pki_config[$e]}"
done | sort
