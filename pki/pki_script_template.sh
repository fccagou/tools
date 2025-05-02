#!/bin/bash

set -euo pipefail


usage () {
	local cmd
	cmd="${0##*/}"
	cmd="${cmd//-/ }"
    cmd="${cmd%%.sh}"
    cat <<EOF_USAGE
Usage: $cmd [--help|help]"

Fonction pas encore implémentée

EOF_USAGE
}


# Variables de configuration
prefix="$(dirname "$(readlink -f "$0")")"
confloader="$prefix"/pki-config-load.sh
CA_DIR="${CA_DIR:-./myCA}"

# Paramètres d'entrée
if [ "$#" == "0" ]; then
	usage
    exit 1
fi

if [ "$1" == "--help" ] || [ "$1" == "help" ]; then
	usage
	exit 0
fi

[ -f "$confloader" ] || {
    echo "Erreur, le fichier de chargement de configuration $confloader est absent." >&2
	exit 1
}

source "$confloader"


# Changer le code suivant.
usage
exit 1

