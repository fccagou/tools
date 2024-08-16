#!/bin/bash

set -euo pipefail

# Variables de configuration
CA_DIR="${CA_DIR:-./myCA}"
CONFIG_FILE="${CA_DIR}/openssl.cnf"
DAYS="${DAYS:-365}"

# Paramètres d'entrée
CERT_NAME=$1

if [ -z "${CERT_NAME}" ]; then
    echo "Usage: $0 <certificate_name>"
    exit 1
fi

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

