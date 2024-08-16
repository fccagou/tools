#!/bin/bash

set -euo pipefail

# Variables de configuration
CA_DIR="${CA_DIR:-./myCA}"
CONFIG_FILE="${CA_DIR}/openssl.cnf"
DAYS="${DAYS:-365}"

[ -f "${CONFIG_FILE}" ] || { echo "Erreur, le fichier de configuration ${CONFIG_FILE} est absent." >&2; exit 1; }

# Paramètres d'entrée
if [ "$#" == "0" ]; then
    echo "Usage: $0 <certificate_name>"
    exit 1
fi

CERT_NAME="$1"

# Génération de la clé privée pour le certificat
openssl genpkey -algorithm RSA -out "${CERT_NAME}".key || { echo "Erreur lors de la génération de la clé privée pour ${CERT_NAME}." >&2; exit 1; }

# Création de la CSR (Certificate Signing Request)
openssl req -new -key "${CERT_NAME}".key -out "${CERT_NAME}".csr || { echo "Erreur lors de la création de la CSR pour ${CERT_NAME}." >&2; exit 1; }

# Signature de la CSR par le CA
openssl ca -config "${CONFIG_FILE}" -in "${CERT_NAME}".csr -out "${CERT_NAME}".crt -days "${DAYS}" || { echo "Erreur lors de la signature du certificat ${CERT_NAME}." >&2; exit 1; }

# Message de fin
echo "Certificat pour ${CERT_NAME} créé avec succès."

