#!/bin/bash

set -euo pipefail

usage () {
	local cmd
	cmd="${0##*/}"
	cmd="${cmd//-/ }"
    cmd="${cmd%%.sh}"
    echo "Usage: $cmd <certificate_name|--help|help>"
}

# Variables de configuration
CA_DIR="${CA_DIR:-./myCA}"
CONFIG_FILE="${CA_DIR}/openssl.cnf"
DAYS="${DAYS:-365}"

[ -f "${CONFIG_FILE}" ] || { echo "Erreur, le fichier de configuration ${CONFIG_FILE} est absent." >&2; exit 1; }

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

# Vérification si le fichier de clé privée existe
if [ ! -f "${CERT_NAME}.key" ]; then
    echo "La clé privée pour ${CERT_NAME} n'existe pas." >&2
    exit 1
fi

# Renouvellement: on génère une nouvelle CSR à partir de la clé existante
openssl req -new -key "${CERT_NAME}".key -out "${CERT_NAME}".csr || { echo "Erreur lors de la création de la nouvelle CSR pour ${CERT_NAME}." >&2; exit 1; }

# Signature de la nouvelle CSR par le CA pour renouveler le certificat
openssl ca -config "${CONFIG_FILE}" -in "${CERT_NAME}".csr -out "${CERT_NAME}".crt -days "${DAYS}" || { echo "Erreur lors du renouvellement du certificat ${CERT_NAME}." >&2; exit 1; }

# Message de fin
echo "Certificat pour ${CERT_NAME} renouvelé avec succès."

