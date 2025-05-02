#!/bin/bash

set -euo pipefail


usage () {
	local cmd
	cmd="${0##*/}"
	cmd="${cmd//-/ }"
    cmd="${cmd%%.sh}"
    cat <<EOF_USAGE
Usage: $cmd [--help|help]"

Affiche les requêtes en cours.

EOF_USAGE
}


# Variables de configuration
prefix="$(dirname "$(readlink -f "$0")")"
confloader="$prefix"/pki-config-load.sh
CA_DIR="${CA_DIR:-./myCA}"

# Paramètres d'entrée
if [ "$#" -eq "1" ]; then
	usage
    exit 0
fi

[ -f "$confloader" ] || {
    echo "Erreur, le fichier de chargement de configuration $confloader est absent." >&2
	exit 1
}

source "$confloader"

if [ "$(ls -1 "$_requestdir"/*.csr 2>/dev/null| wc -l)" -eq "0" ]; then
	echo "Aucune requête en cours"
else
	for f in $(ls -1 "$_requestdir"/*.csr 2>/dev/null); do
		echo "------- [$f]"
		{
		  openssl req -in "$f" -subject -noout | sed -e 's/^subject=/subject: /'
		  date_c="$(stat --format "%w" "$f")"
		  date_m="$(stat --format "%y" "$f")"
          printf -- " create: %s\n" "${date_c}"

		  if [ "${date_m}" != "${date_c}" ]; then
			  printf -- " modify: %s\n" "${date_m}"
		  fi
	    }

	done
fi

