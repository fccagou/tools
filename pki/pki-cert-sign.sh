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
    echo "Usage: $0 <chemin vers le fichier csr>"
    exit 1
fi

CSR_FILENAME="$1"

[ -f "${CSR_FILENAME}" ] || {
	echo "Erreur, le fichier csr ${CSR_FILENAME} est absent." >&2
	exit 1
}

if [ "${CSR_FILENAME%%.csr}" == "${CSR_FILENAME}" ]; then
	CERT_NAME="${CSR_FILENAME}".pem
else
	CERT_NAME="${CSR_FILENAME%%.csr}".pem
fi


# -extensions tls_"${CERT_TYPE}" \
# Signature de la CSR par le CA
openssl ca -days "${DAYS}" \
	-config "${CONFIG_FILE}" \
	-in "${CSR_FILENAME}" \
	-out "${CERT_NAME}" \
	|| { echo "Erreur lors de la signature du certificat ${CERT_NAME}." >&2; exit 1; }

# Message de fin
echo "Certificat ${CERT_NAME} signé avec succès."

