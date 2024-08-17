#!/bin/bash

set -euo pipefail

usage () {
	local cmd
	cmd="${0##*/}"
	cmd="${cmd//-/ }"
    cmd="${cmd%%.sh}"
    echo "Usage: $cmd <Nom du certificat|--help|help>"
}


# Variables de configuration
CA_DIR="${CA_DIR:-./myCA}"
CONFIG_FILE="${CA_DIR}/openssl.cnf"
CRL_FILE="${CA_DIR}/crl/ca.crl"

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

CERT_NAME="${1// /-}"


# Vérification si le fichier du certificat existe
if [ ! -f "${CERT_NAME}" ]; then
    echo "Le certificat ${CERT_NAME} n'existe pas." >&2
    exit 1
fi

# Révocation du certificat
openssl ca -config "${CONFIG_FILE}" -revoke "${CERT_NAME}" || { echo "Erreur lors de la révocation du certificat ${CERT_NAME}." >&2; exit 1; }

# Génération d'une nouvelle CRL
openssl ca -config "${CONFIG_FILE}" -gencrl -out "${CRL_FILE}" || { echo "Erreur lors de la génération de la nouvelle CRL (${CRL_FILE})." >&2; exit 1; }

# Message de fin
echo "Certificat ${CERT_NAME} révoqué avec succès. Nouvelle CRL générée (${CRL_FILE})."

