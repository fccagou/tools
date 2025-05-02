#!/bin/bash

set -euo pipefail

usage () {
	local cmd
	cmd="${0##*/}"
	cmd="${cmd//-/ }"
    cmd="${cmd%%.sh}"
    echo "Usage: $cmd <certificate_name|--help|help>"
}


# Paramètres d'entrée
if [ "$#" == "0" ]; then
	usage
    exit 1
fi

if [ "$1" == "--help" ] || [ "$1" == "help" ]; then
	usage
	exit 0
fi

CERT_NAME="$1"
prefix="$(dirname "$(readlink -f "$0")")"
confloader="$prefix"/pki-config-load.sh

source "$confloader"

# Vérifier s'il y a déjà une requete en cours

# Vérification si le fichier de clé privée existe
if [ ! -f "$_privatedir"/"${CERT_NAME}.key" ]; then
    echo "La clé privée pour ${CERT_NAME} n'existe pas." >&2
    exit 1
fi

"$prefix"/pki request new "$CERT_NAME"
"$prefix"/pki cert sign "$CERT_NAME"

# Message de fin
echo "Certificat pour ${CERT_NAME} renouvelé avec succès."

