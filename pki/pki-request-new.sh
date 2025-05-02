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
prefix="$(dirname "$(readlink -f "$0")")"
confloader="$prefix"/pki-config-load.sh

CA_DIR="${CA_DIR:-./myCA}"
CONFIG_FILE="${CA_DIR}/openssl.cnf"
DAYS="${DAYS:-365}"
CERT_TYPE=server

C="${C:-VU}"
ST="${ST:-Efate}"
L="${L:-Port-Vila}"
O="${O:-"Test org"}"
OU="${OU:-"IT of $O"}"
BATCHMODE="${BATCHMODE:-no}"
SAN="${SAN:-""}"

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

if [ -f "$_privatedir"/"${CERT_NAME}".key ]; then
	echo "Clef existante => RENEW"
else
	# Génération de la clé privée pour le certificat
	openssl genpkey -algorithm RSA -quiet \
		-out "$_privatedir"/"${CERT_NAME}".key \
		|| { echo "Erreur lors de la génération de la clé privée pour ${CERT_NAME}." >&2; exit 1; }
fi

if [ -z "$SAN" ]; then
    SAN="DNS:${CERT_NAME//:*}"
else
	# From env, check value DNS:xxxxx, DNS:yyyy, IP:zzzz
	SAN_CHECK="$(echo "$SAN" | xargs | sed -e 's/[;"].*//')"
	if [ "$SAN_CHECK" != "$CHECK" ]; then
		echo "ERROR: la valeur SAN n'est pas convenable ($SAN) (man openssl)"
		exit 0
	fi
fi
# Création de la CSR (Certificate Signing Request)
openssl req -new \
	-config "${CONFIG_FILE}" \
	-extensions tls_"${CERT_TYPE}" \
	-copy_extensions copyall \
	-subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=${CERT_NAME}" \
	-key "$_privatedir"/"${CERT_NAME}".key \
	-out "$_requestdir"/"${CERT_NAME}".csr \
	-addext "subjectAltName = $SAN" \
	|| { echo "Erreur lors de la création de la CSR pour ${CERT_NAME}." >&2; exit 1; }

# Message de fin
echo "Requtête de Certificat pour ${_requestdir}/${CERT_NAME}.csr créée avec succès."

