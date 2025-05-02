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
prefix="$(dirname "$(readlink -f "$0")")"
confloader="$prefix"/pki-config-load.sh
CA_DIR="${CA_DIR:-./myCA}"
CONFIG_FILE="${CA_DIR}/openssl.cnf"
DAYS="${DAYS:-365}"
BATCHMODE="${BATCHMODE:-no}"

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

[ "$BATCHMODE" == "yes" ] && batchopt='-batch' || batchopt=''
# -extensions tls_"${CERT_TYPE}"

san=( $(_req_get_san "$CSR_FILENAME") )

if [ "${#san}" -eq 0 ]; then
	san_names="DNS.1=${CSR_FILENAME//:*}"
else
	# Transform DNS:xxxx, DNS:yyyy
	i=1
	k=""
	v=""
	prevk=""
	san_names=""
	for n in ${san[@]}; do
		k="${n//:*}"
		v="${n//*:}"
		v="${v//,*}"
		if [ "$k" == "$prevk" ]; then
			i=$(( i + 1 ))
		else
			i=1
			prevk="$k"
		fi
		san_names="$san_names\n$k.$i=$v"
	done
fi

# Signature de la CSR par le CA
openssl ca -days "${DAYS}" $batchopt \
	-config "${CONFIG_FILE}" \
	-in "${csrrealname}" \
	-out "$_certsdir"/"$certname" \
	-extensions SAN \
	-extfile <(cat "${CONFIG_FILE}" <(printf -- "[san_names]\n${san_names}\n")) \
	|| { echo "Erreur lors de la signature du certificat ${csrrealname}." >&2; exit 1; }


# On renomme pour ne plus le voir apparaître dans la liste.;
mv "$csrrealname"{,.done}
# Message de fin
echo "Certificat $_certsdir/$certname signé avec succès."

