#!/bin/bash

set -euo pipefail

usage () {
	local cmd
	cmd="${0##*/}"
	cmd="${cmd//-/ }"
    cmd="${cmd%%.sh}"
	cat <<-EOF
Usage: $cmd [--batch] [--initfile filename] [ca_dir]
EOF
}


# Variables de configuration
CA_DIR="${CA_DIR:-./myCA}"
CA_KEY="${CA_DIR}/private/cakey.pem"
CA_CERT="${CA_DIR}/cacert.pem"
CONFIG_FILE="${CA_DIR}/openssl.cnf"
DAYS="${DAYS:-3650}"
INITFILE="${INITFILE:-""}"

C="${C:-VU}"
ST="${ST:-Efate}"
L="${L:-Port-Vila}"
O="${O:-"Test org"}"
OU="${OU:-"IT of $O"}"
CN="${CN:-"CA of $O"}"

BATCHMODE="${BATCHMODE:-no}"

cafromparam=""

while [ "$#" -gt 0 ]; do
	case "$1" in
		--help|-h|help)
			usage
			exit 0
			;;
		--batch) BATCHMODE=yes ;;
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
			[ -z "$cafromparam" ] || {
			  echo "Parametre inconnu ($1)"
			  usage
			  exit 1
		    }
			cafromparam="${1// /-}"
			;;
	esac
	shift
done

[ -z "$cafromparam" ] || CA_DIR="$cafromparam"

if [ -n "$INITFILE" ]; then
	[ ! -f "$INITFILE" ] && {
	    echo "Erreur, le fichier de configuration $INITFILE n'existe pas"
        exit 1
    }
	source "$INITFILE"
fi




cat <<-EOF_BANNER
Création d'une CA avec les informations suivantes:

    CA_DIR=${CA_DIR}
    CA_KEY=${CA_DIR}/private/cakey.pem"
    CA_CERT=${CA_DIR}/cacert.pem"
    CONFIG_FILE=${CA_DIR}/openssl.cnf"
    DAYS=${DAYS}
    INITFILE=${INITFILE}

    C=$C
    ST=$ST
    L=$L
    O=$O
    OU=$OU
    CN=$CN

EOF_BANNER


if [ "$BATCHMODE" == "yes" ]; then
    batchopt='-batch'
	encopt=''

	echo "******************************************************************"
	echo "*"
	echo "*    Création en mode batch."
	echo "*"
	echo "*       => PAS DE CHIFFREMENT POUR LA CLEF PRIVEE DE LA CA"
	echo "*"
	echo "******************************************************************"

else
    batchopt=''
	encopt='-aes256'

    rep=""
    while :; do
	    read -rp "Voulez-vous poursuivre avec ces informations ? [O/n]" rep

		case "$rep" in
			N|n)
				echo "Annulation par l'utilisateur"
				exit 0
				;;
			O|o|Y|y|'')
				break
				;;
			*)
				echo "Réponse inconnue $rep";
		esac
	done


	[ -d "${CA_DIR}" ] && {
		rep=""
	    while :; do
	        read -rp "ATTENTION: ${CA_DIR} existe déjà, voulez-vous poursuivre tout de même ? [O/n]" rep
			case "$rep" in
				N|n)
					echo "Annulation par l'utilisateur"
					exit 0
					;;
				O|o|Y|y|'')
					break
					;;
				*)
					echo "Réponse inconnue $rep";
			esac
		done
	}
fi

if [ -d "${CA_DIR}" ]; then
	[ -d "${CA_DIR}"_backup ] && rm -rf "${CA_DIR}"_backup
	mv "${CA_DIR}" "${CA_DIR}"_backup
	echo "Backup ancienne configuration dans ${CA_DIR}_backup"
fi

# Création des répertoires et fichiers nécessaires
mkdir -p "${CA_DIR}"/{certs,crl,newcerts,private,req} || { echo "Erreur lors de la création des répertoires." >&2; exit 1; }
chmod 700 "${CA_DIR}"/private || { echo "Erreur lors du changement des permissions." >&2; exit 1; }
touch "${CA_DIR}"/index.txt || { echo "Erreur lors de la création du fichier index.txt." >&2; exit 1; }
echo 1000 > "${CA_DIR}"/serial || { echo "Erreur lors de la création du fichier serial." >&2; exit 1; }

echo "Création du fichier de configuration ${CONFIG_FILE}"

source ./pki-config-create.sh

# Génération de la clé privée pour le CA
# TODO: vérifier la force de l'aes256
echo "Création de la clef privéee ${CA_KEY}"
openssl genpkey -quiet -algorithm RSA -out "${CA_KEY}" $encopt || { echo "Erreur lors de la génération de la clé privée." >&2; exit 1; }

# Génération du certificat racine pour le CA
echo "Création du certificat ${CA_CERT}"
openssl req -x509 -new -nodes -sha256 -days "$DAYS" $batchopt \
	-config "${CONFIG_FILE}" \
	--extensions v3_ca \
	-subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN" \
	-key "${CA_KEY}"  \
	-out "${CA_CERT}" \
	|| { echo "Erreur lors de la création du certificat racine." >&2; exit 1; }

openssl x509 -in  "${CA_CERT}" -noout -text

# Message de fin
echo "Infrastructure PKI initialisée avec succès."
