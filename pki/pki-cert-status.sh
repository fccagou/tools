#!/bin/bash

set -euo pipefail

usage () {
	local cmd
	cmd="${0##*/}"
	cmd="${cmd//-/ }"
    cmd="${cmd%%.sh}"
    echo "Usage: $cmd <chemin vers le fichier certificat|serial|--help|help>"
}

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


CERT_NAME=$1

# Vérification si le fichier existe
if [ ! -f "${CERT_NAME}" ]; then
	if [ -f "${CA_DIR}"/newcerts/"${CERT_NAME}".pem ] ; then
		serial="${CERT_NAME}"
		CERT_NAME="${CA_DIR}"/newcerts/"${serial}".pem
	else
        echo "Le certificat ${CERT_NAME} n'existe pas." >&2
        exit 1
	fi
fi

# Vérification des dates de validité
echo "-------"
echo "serial=$serial"
openssl x509 -in "${CERT_NAME}" -noout -subject -issuer -dates || {
	echo "Erreur lors de la vérification des dates de validité pour ${CERT_NAME}." >&2
	exit 1
}

# Message de fin
echo "Vérification des dates de validité terminée pour ${CERT_NAME}."


