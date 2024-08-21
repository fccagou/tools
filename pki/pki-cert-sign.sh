#!/bin/bash

set -euo pipefail

usage () {
	local cmd
	cmd="${0##*/}"
	cmd="${cmd//-/ }"
    cmd="${cmd%%.sh}"
    echo "Usage: $cmd <chemin vers le fichier csr|--help|help>"
}


# Variables de configuration
prefix="$(readlink -f "$(dirname "$0")")"
confloader="$prefix"/pki-config-load.sh
CA_DIR="${CA_DIR:-./myCA}"
CONFIG_FILE="${CA_DIR}/openssl.cnf"
DAYS="${DAYS:-365}"

CERT_TYPE=server

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
CSR_FILENAME="$1"

certsdir="$(_config_get "${_ca}.certs")"
csrrealname=""
certname=""

filenames=(
	"${CSR_FILENAME}"
	"${CSR_FILENAME}".csr
	"$_requestdir"/"${CSR_FILENAME}"
	"$_requestdir"/"${CSR_FILENAME}".csr
)


for f in "${filenames[@]}"; do
	[ -f "$f" ] && {
		csrrealname="$f"
	    break
	}
done

[ -n "$csrrealname" ]  || {
	echo "Erreur, le fichier csr ${CSR_FILENAME} est introuvable." >&2
	exit 1
}


tmp="${csrrealname##*/}"

if [ "${tmp%%.csr}" == "${tmp}" ]; then
	certname="${tmp}".pem
else
	certname="${tmp%%.csr}".pem
fi


# -extensions tls_"${CERT_TYPE}" \
# Signature de la CSR par le CA
openssl ca -days "${DAYS}" \
	-config "${CONFIG_FILE}" \
	-in "${csrrealname}" \
	-out "$certsdir"/"$certname" \
	|| { echo "Erreur lors de la signature du certificat ${csrrealname}." >&2; exit 1; }

# On renomme pour ne plus le voir apparaître dans la liste.;
mv "$csrrealname"{,.done}
# Message de fin
echo "Certificat $certsdir/$certname signé avec succès."

