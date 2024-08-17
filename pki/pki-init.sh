#!/bin/bash

set -euo pipefail

usage () {
	cat <<-EOF
Usage: $0 [--initfile filename]
EOF
}



# Variables de configuration
CA_DIR="${CA_DIR:-./myCA}"
CA_KEY="${CA_DIR}/private/cakey.pem"
CA_CERT="${CA_DIR}/cacert.pem"
CONFIG_FILE="${CA_DIR}/openssl.cnf"
DAYS="${DAYS:-3650}"
INITFILE="${INITFILE:-""}"

C=VU
ST=Efate
L=Port-Vila
O="Test org"
OU="IT of $O"
CN="CA of $O"



while [ "$#" -gt 0 ]; do
	case "$1" in
		--help|-h|help)
			usage
			exit 0
			;;
		--initfile)
			if [ "$#" == 2 ]; then
			    INITFILE="$2"
				shift
			else
				echo "Erreur, il manque le nom du fichier d'initialisation"
				usage
			    exit 1
			fi
			;;
		*)
			echo "Parametre inconnu ($1)"
			usage
			exit 1
			;;
	esac
	shift
done


if [ -n "$INITFILE" ]; then
	[ ! -f "$INITFILE" ] && {
	    echo "Erreur, le fichier de configuration $INITFILE n'existe pas"
        exit 1
    }
	source "$INITFILE"
fi

# Création des répertoires et fichiers nécessaires
mkdir -p "${CA_DIR}"/{certs,crl,newcerts,private} || { echo "Erreur lors de la création des répertoires." >&2; exit 1; }
chmod 700 "${CA_DIR}"/private || { echo "Erreur lors du changement des permissions." >&2; exit 1; }
touch "${CA_DIR}"/index.txt || { echo "Erreur lors de la création du fichier index.txt." >&2; exit 1; }
echo 1000 > "${CA_DIR}"/serial || { echo "Erreur lors de la création du fichier serial." >&2; exit 1; }

echo "Création du fichier de configuration ${CONFIG_FILE}"

source ./pki-config-create.sh

# Génération de la clé privée pour le CA
# TODO: vérifier la force de l'aes256
openssl genpkey -algorithm RSA -out "${CA_KEY}" -aes256 || { echo "Erreur lors de la génération de la clé privée." >&2; exit 1; }

# Génération du certificat racine pour le CA
openssl req -x509 -new -nodes -sha256 -days "$DAYS" \
	-config "${CONFIG_FILE}" \
	--extensions v3_ca \
	-subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN" \
	-key "${CA_KEY}"  \
	-out "${CA_CERT}" \
	|| { echo "Erreur lors de la création du certificat racine." >&2; exit 1; }

openssl x509 -in  "${CA_CERT}" -noout -text

# Message de fin
echo "Infrastructure PKI initialisée avec succès."
