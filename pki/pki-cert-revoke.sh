#!/bin/bash

set -euo pipefail

# Variables de configuration
CA_DIR="${CA_DIR:-./myCA}"
CONFIG_FILE="$CA_DIR/openssl.cnf"
CRL_FILE="$CA_DIR/crl/ca.crl"

# Paramètres d'entrée
CERT_NAME=$1

if [ -z "$CERT_NAME" ]; then
    echo "Usage: $0 <certificate_name.crt>"
    exit 1
fi

# Vérification si le fichier du certificat existe
if [ ! -f "$CERT_NAME" ]; then
    echo "Le certificat $CERT_NAME n'existe pas." >&2
    exit 1
fi

# Révocation du certificat
openssl ca -config $CONFIG_FILE -revoke $CERT_NAME || { echo "Erreur lors de la révocation du certificat $CERT_NAME." >&2; exit 1; }

# Génération d'une nouvelle CRL
openssl ca -config $CONFIG_FILE -gencrl -out $CRL_FILE || { echo "Erreur lors de la génération de la nouvelle CRL." >&2; exit 1; }

# Message de fin
echo "Certificat $CERT_NAME révoqué avec succès. Nouvelle CRL générée."

