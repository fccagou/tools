#!/bin/bash

set -euo pipefail


usage () {
	local cmd
	cmd="${0##*/}"
	cmd="${cmd//-/ }"
    cmd="${cmd%%.sh}"
    echo "Usage: $cmd <nom du certificat|--help|help>"
}


# Variables de configuration
prefix="$(readlink -f "$(dirname "$0")")"
confloader="$prefix"/pki-config-load.sh

CA_DIR="${CA_DIR:-./myCA}"
CONFIG_FILE="${CA_DIR}/openssl.cnf"
DAYS="${DAYS:-365}"

CERT_TYPE=server

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

CERT_NAME="${1// /-}"

# Génération de la clé privée pour le certificat
openssl genpkey -algorithm RSA \
	-out "$_privatedir"/"${CERT_NAME}".key \
	|| { echo "Erreur lors de la génération de la clé privée pour ${CERT_NAME}." >&2; exit 1; }

# Création de la CSR (Certificate Signing Request)
openssl req --new \
	-config "${CONFIG_FILE}" \
	-extensions tls_"${CERT_TYPE}" \
	-copy_extensions copyall \
	-key "$_privatedir"/"${CERT_NAME}".key \
	-out "$_requestdir"/"${CERT_NAME}".csr \
	|| { echo "Erreur lors de la création de la CSR pour ${CERT_NAME}." >&2; exit 1; }

# Message de fin
echo "Requtête de Certificat pour ${_requestdir}/${CERT_NAME}.csr créée avec succès."

