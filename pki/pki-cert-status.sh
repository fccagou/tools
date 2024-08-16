#!/bin/bash

set -euo pipefail

# Paramètres d'entrée
CERT_NAME=$1

if [ -z "${CERT_NAME}" ]; then
    echo "Usage: $0 <certificate_name.crt>"
    exit 1
fi

# Vérification si le fichier existe
if [ ! -f "${CERT_NAME}" ]; then
    echo "Le fichier ${CERT_NAME} n'existe pas." >&2
    exit 1
fi

# Vérification des dates de validité
openssl x509 -in "${CERT_NAME}" -noout -dates || { echo "Erreur lors de la vérification des dates de validité pour ${CERT_NAME}." >&2; exit 1; }

# Message de fin
echo "Vérification des dates de validité terminée pour ${CERT_NAME}."


