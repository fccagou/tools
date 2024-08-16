#!/bin/bash

set -euo pipefail

# Variables de configuration
CA_DIR="${CA_DIR:-./myCA}"
CONFIG_FILE="${CA_DIR}/openssl.cnf"
DAYS=365

# Paramètres d'entrée
CERT_NAME=$1

if [ -z "${CERT_NAME}" ]; then
    echo "Usage: $0 <certificate_name>"
    exit 1
fi

# Génération de la clé privée pour le certificat
openssl genpkey -algorithm RSA -out "${CERT_NAME}".key || { echo "Erreur lors de la génération de la clé privée pour ${CERT_NAME}." >&2; exit 1; }

# Création de la CSR (Certificate Signing Request)
openssl req -new -key "${CERT_NAME}".key -out "${CERT_NAME}".csr || { echo "Erreur lors de la création de la CSR pour ${CERT_NAME}." >&2; exit 1; }

# Signature de la CSR par le CA
openssl ca -config "${CONFIG_FILE}" -in "${CERT_NAME}".csr -out "${CERT_NAME}".crt -days "${DAYS}" || { echo "Erreur lors de la signature du certificat ${CERT_NAME}." >&2; exit 1; }

# Message de fin
echo "Certificat pour ${CERT_NAME} créé avec succès."

