#!/bin/bash

set -euxo pipefail

usage () {
	local cmd
	cmd="${0##*/}"
	cmd="${cmd//-/ }"
    cmd="${cmd%%.sh}"
    echo "Usage: $cmd <Nom du certificat|--help|help>"
}


# Variables de configuration
prefix="$(dirname "$(readlink -f "$0")")"
confloader="$prefix"/pki-config-load.sh

CA_DIR="${CA_DIR:-./myCA}"
CONFIG_FILE="${CA_DIR}/openssl.cnf"
CRL_FILE="${CA_DIR}/crl/ca.crl"


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


# Vérification si le fichier du certificat existe
if [ ! -f "$_certsdir"/"${CERT_NAME}".pem ]; then
    echo "Le certificat ${CERT_NAME} n'existe pas." >&2
    exit 1
fi

# Révocation du certificat
openssl ca -config "${CONFIG_FILE}" -revoke "$_certsdir"/"${CERT_NAME}".pem || { echo "Erreur lors de la révocation du certificat ${CERT_NAME}." >&2; exit 1; }

# Génération d'une nouvelle CRL
openssl ca -config "${CONFIG_FILE}" -gencrl -out "${CRL_FILE}" || { echo "Erreur lors de la génération de la nouvelle CRL (${CRL_FILE})." >&2; exit 1; }

# Message de fin
echo "Certificat ${CERT_NAME} révoqué avec succès. Nouvelle CRL générée (${CRL_FILE})."

