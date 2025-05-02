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
prefix="$(dirname "$(readlink -f "$0")")"
confloader="$prefix"/pki-config-load.sh
CA_DIR="${CA_DIR:-./myCA}"

[ -f "$confloader" ] || {
    echo "Erreur, le fichier de chargement de configuration $confloader est absent." >&2
	exit 1
}
source "$confloader"
newcertsdir="$(_config_get "${_ca}.new_certs_dir")"

if [ "$(ls -1 "$newcertsdir"/*.pem 2>/dev/null| wc -l)" -eq "0" ]; then
	echo "Aucun certifiat pour l'instant"
else
	for f in $(ls -1 "$newcertsdir"/*.pem 2>/dev/null); do
		echo "------- ($f)"
		tmp="${f##*/}"
		echo "serial=${tmp%%.pem}"
		openssl x509 -in "$f" -subject -issuer -dates -noout
	done
fi

