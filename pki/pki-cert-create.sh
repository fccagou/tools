#!/bin/bash

set -euo pipefail

# Variables de configuration
CA_DIR="${CA_DIR:-./myCA}"
CONFIG_FILE="${CA_DIR}/openssl.cnf"
DAYS="${DAYS:-365}"

CERT_TYPE=server


[ -f "${CONFIG_FILE}" ] || { echo "Erreur, le fichier de configuration ${CONFIG_FILE} est absent." >&2; exit 1; }

# Paramètres d'entrée
if [ "$#" == "0" ]; then
    echo "Usage: $0 <certificate_name>"
    exit 1
fi

CERT_NAME="$1"

# REM: ici on génère toout car on est dans le cas de systèmes de tests, par contre
#      en production,
#      - soit c'est le demandeur qui génère la clef privée et la
#      demande de certificat,
#      - soit c'est la pki qui doit alors faire un pkcs12
#      et demander un mdp que seul le client doit connaître.
#
# Génération de la clé privée pour le certificat
openssl genpkey -algorithm RSA \
	-out "${CERT_NAME}".key \
	|| { echo "Erreur lors de la génération de la clé privée pour ${CERT_NAME}." >&2; exit 1; }

# Création de la CSR (Certificate Signing Request)
openssl req --new \
	-config "${CONFIG_FILE}" \
	-copy_extensions copyall \
	-key "${CERT_NAME}".key \
	-out "${CERT_NAME}".csr \
	|| { echo "Erreur lors de la création de la CSR pour ${CERT_NAME}." >&2; exit 1; }

# Signature de la CSR par le CA
openssl ca -days "${DAYS}" \
	-config "${CONFIG_FILE}" \
	-extensions tls_"${CERT_TYPE}" \
	-in "${CERT_NAME}".csr \
	-out "${CERT_NAME}".pem \
	|| { echo "Erreur lors de la signature du certificat ${CERT_NAME}." >&2; exit 1; }

# Message de fin
echo "Certificat pour ${CERT_NAME} créé avec succès."

