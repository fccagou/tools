#!/bin/bash

set -euo pipefail

usage () {
	local cmd
	cmd="${0##*/}"
	cmd="${cmd//-/ }"
    cmd="${cmd%%.sh}"
    echo "Usage: $cmd <chemin vers le fichier certificat|serial|--help|help>"
}

# Variables de configuration
prefix="$(dirname "$(readlink -f "$0")")"
confloader="$prefix"/pki-config-load.sh

# Paramètres d'entrée
CA_DIR="${CA_DIR:-myCA}"
serial="unknown"

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

CERT_NAME="$1"

# Vérification si le fichier existe
if [ ! -f "${CERT_NAME}" ]; then
	if [ -f "${CA_DIR}"/newcerts/"${CERT_NAME}".pem ] ; then
		serial="${CERT_NAME}"
		CERT_FILE="${CA_DIR}"/newcerts/"${serial}".pem
	elif [ -f "$_certsdir"/"${CERT_NAME}".pem ]; then
		CERT_FILE="$_certsdir"/"${CERT_NAME}".pem
		serial="$(openssl x509 -in "$CERT_FILE" -noout -serial | cut -d = -f2)"
	else
        echo "Le certificat ${CERT_NAME} n'existe pas." >&2
        exit 1
	fi
fi

# Vérification des dates de validité
echo "-------(${CERT_FILE})"
echo "serial=$serial"
{
	openssl x509 -in "${CERT_FILE}" -noout -fingerprint -subject -issuer -dates -sha256;
	printf -- "subjectAlternateName=%s\n" "$(_cert_get_san "$CERT_FILE")"
} || {
	echo "Erreur lors de la vérification des dates de validité pour ${CERT_FILE}." >&2
	exit 1
}
# Message de fin
#echo "Vérification des dates de validité terminée pour ${CERT_NAME}."


