#!/bin/bash
set -euo pipefail

usage () {
	local cmd
	cmd="${0##*/}"
	cmd="${cmd//-/ }"
    cmd="${cmd%%.sh}"
	cat <<-EOF_USAGE
Usage: $cmd [--help]

Charge le fichier de configuration ${CONFIG_FILE}

   source ${CONFIG_FILE}

EOF_USAGE
}


_config_default_ca() {
	local section
	section="${1:-ca}"

	printf -- '%s'  "${pki_config[$section.default_ca]}"
}

_config_get () {
	local key
	local val
	local _dir
	key="$1"
	val="${pki_config[$key]}"
	printf -- '%s' "${val//\$dir/${CA_DIR}}"

}


# Variables de configuration
CA_DIR="${CA_DIR:-./myCA}"
CONFIG_FILE="${CA_DIR}/openssl.cnf"

[ "$#" -ge "1" ] && [ "$1" == "--help" ] && {
	usage
    exit 1
} || :


[ -f "${CONFIG_FILE}" ] || {
    echo "Erreur, fichier de configuration ${CONFIG_FILE} inconnu." >&2
    exit 1
}

declare -A pki_config
section=""


while read -r l; do
	case "$l" in
		[*)
			section="${l:1:${#l}}"
			;;
		*=*)
			pki_config["$section.${l//=*/}"]="${l//*=/}"

			;;
		*)
			echo "# $l"
			;;
	esac
done <<<$( sed -e 's/[[:space:]]*#.*//' \
	        -e 's/\[ *\([^ ]*\) *\]/[\1/' \
	        -e 's/[[:space:]]*=[[:space:]]*\(.*\)[[:space:]]*$/=\1/' \
	        "${CONFIG_FILE}" \
	        | grep -vE '^[[:space:]]*$' \
		)

## Global configuration
_ca="$(_config_default_ca)"
_privatedir="${CA_DIR}"/private
_requestdir="${CA_DIR}"/req
_certsdir="$(_config_get "${_ca}.certs")"
