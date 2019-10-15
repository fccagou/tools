#!/bin/sh
# -*- encoding: utf-8 -*-

# ---------------------------------------------------------------------
# WHY ... But well, this is a job ...
# ---------------------------------------------------------------------
# TODO: détermine xfreerdb version to select parameters version
#
freerdp_version="$(xfreerdp --version | awk '{ print $5 }')"
release="${version%.*}"
major="${release%.*}"
minor="${release#*.}"
use_old_args=0


# ---------------------------------------------------------------------
# VARS
# ---------------------------------------------------------------------
PGM=${PGM:-$(basename $0)}
# Variables
RESTORE='\033[0m'
RED='\033[00;31m'
GREEN='\033[00;32m'
DEBUG=1


SITE="MYCORP"
GROUP="IT"
SEC="nla"
SCREEN_SIZE="full"
SCREEN_RESOLUTION=""

# ---------------------------------------------------------------------
# Local functions
# ---------------------------------------------------------------------

error () {
	echo -e "${RED}[-] ${*}${RESTORE}"
}
warning () {
	echo -e "${RED}[!]${RESTORE} ${*}"
}

action () {
	echo -e "${GREEN}[+]${RESTORE} ${*}"
}

info() {
   printf -- "[-] ${*}"
}


usage () {
   cat <<EOF_USAGE

Usage: ${PGM} [-h|--help] [--site site_name] [--group group_of_hosts]
	   [--sec rdp|tls|nla|ext] [--certificate ignore|certificate_file_name]
	   [--resolution] full|XX%|WxH]
	   <login> <domain> <hostname>

     --site          : discribe the remote site to connect to (just informational)
     --group         : discribe the remote group of servers (just informational)
     --sec           : rdp security type values are 
                       - rdp : not safe
                       - tls : tls encryption
                       - nla : network security (default)
                       - ext : nla extended
     --certificate   :  values are 
                       - ignore (very bad idea)
                       - certificate filename 
     --resolution    : diplay resolution. values are 
                       - full : fullscreen (default)
                       - WxH  : (W)idth  (H)eight in pixel
					   - XX%  : for a percent of the current resolution (0<= XX < 99)
	 --old-params    : use old type parameters (IT only usage)
	 --debug         : debug mode (IT usage only)
     -h|--help       : this help
     login           : remote host login
     domain          : kerberos domain name
     hostname        : remote rdp host

EOF_USAGE
}

# ---------------------------------------------------------------------
# Sanitizers
# ---------------------------------------------------------------------

is_num () {
	# TODO: try using shell cmd.
	awk -v val=${1} 'function isnum(x){return(x==x+0)} BEGIN{print isnum(val)}'
}

check_exploit () {
	# TODO
	# Check if the string contains exploit data
	local STRING="${1}"
	
}

check_user () {
	# TODO
	local USER="${1}"

}

check_domain () {
	# TODO
	# DOMAIN contains only alphanum and '.' characters
	local DOMAIN="${1}"
			
}

check_hostname () {
	# TODO
	local HOSTNAME="${1}"	
}

check_site (){
	# TODO
	# must not special char.
	local SITE="${1}"
}
check_group (){
	# TODO
	# Alphanum only
	local GROUP="${1}"
}



check_sec (){
	case "${1}" in
		rdp | tls | nla | ext )
			:
			;;
		*)
			error "Bad sec parameter (${1})"
			usage
			exit 2
			;;
	esac
}


check_certificate (){
	local CERTIFICATE="${1}"
	[ "${CERTIFICATE}" == "ignore" ] && return

	# Certificate must be readable file
	grep -q -- "-BEGIN CERTIFICATE-" ${CERTIFICATE}  2>/dev/null || {
		error "bad certificate (${CERTIFICATE})";
		exit 3;
	}

}

check_screen_size () {
	# According to usage help
	case ${1} in
		full )
			[ $DEBUG ] && info "Fullscreen\n"
			SCREEN_RESOLUTION="${fullscreen_param}"
			;;

		*%)
			V=${1/\%*}
			[ $DEBUG ] && info "percent ${V}\n"
			[ "$(is_num ${V})" == "0" -o ${V} -lt 0 -o ${V} -gt 99 ] && {
				error "Percent value must be >=0 and <100";
				exit 3;
			}
			if [ $use_old_args ]
			then
				SCREEN_RESOLUTION="${scale_param}${V}%"
			else
				SCREEN_RESOLUTION="${scale_param}${V}"
			fi
			;;

		*x*)
			W=${1/x*}
			H=${1#*x}
			[ $DEBUG ] && info "WxH ${W}x${H}\n"
		
			[ "$(is_num ${W})" == "1" -a "$(is_num ${H})" == "1" ] || {
				error "W and H must be positives integers";
				exit 3;
			}
		 	SCREEN_RESOLUTION="${size_param}${W}x${H}"	
			;;

		*)
			error "Bad screen resolution (${1})"
			usage
			exit 3
			;;
	esac
}

# ---------------------------------------------------------------------
# Args parsing
# ---------------------------------------------------------------------
# This an example
#

while true
do
	case "${1}" in
		--site )
			check_exploit "${2}"
			check_site "${2}"
			SITE="${2}"
			shift
			;;
		--group )
			check_exploit "${2}"
			check_group "${2}"
			GROUP="${2}"
			shift
			;;
		--sec )
			check_exploit "${2}"
			check_sec "${2}"
			SEC="${2}"
			shift
			;;
		--certificate )
			check_exploit "${2}"
			check_certificate "${2}"
			CERTIFICATE="${2}"
			shift
			;;
		--resolution )
			check_exploit "${2}"
			SCREEN_SIZE="${2}"
			shift
			;;
		-h | --help )
			usage
			exit 0
			;;
		# Internal usage
		--debug )
			DEBUG=0
			;;
		--old-params )
			use_old_args=1
			;;
		*) 
			break
			;;
	esac
	shift
done


if [ $# -lt 3 ]
then
	error "Not enough arguments"
	usage
	exit 1
fi


check_exploit "${1}"
check_exploit "${2}"
check_exploit "${3}"

# Everything must be safe here


USER="${1}"
DOMAIN="${2}"
REMOTE_HOST="${3}"


# ---------------------------------------------------------------------
#  YOU HAD ONE JOB
# ---------------------------------------------------------------------
if [ ${use_old_args} -eq 1 ]
then
	cert_name_param=' '
	ignore_cert_param='--ignore-certificate'
	network_param="-x l"
	sec_param="--sec "
	login_param='-u '
    domain_param="-d "
	clipboard_param='--plugin cliprdr'
	share_param="--plugin rdpsnd --plugin rdpdr --data disk:"
	title_param="-T "
	size_param="-g "
	scale_param="-g "
    fullscreen_param="-f"
	host_param=" -- "
else
	cert_name_param='/cert-name:'
	ignore_cert_param='/cert-ignore'
	network_param="/network:auto"
	sec_param="/sec:"
	login_param="/u:"
    domain_param="/d:"
	clipboard_param="+clipboard"
	share_param="/drive:"
	title_param="/t:"
	size_param="/size:"
	scale_param="/scale:"
    fullscreen_param="/f"
	host_param="/v:"
fi


# ---------------------------------------------------------------------
# Params
# ---------------------------------------------------------------------

check_user "${USER}"
check_domain "${DOMAIN}"
check_hostname "${REMOTE_HOST}"
check_screen_size "${SCREEN_SIZE}"


# Create a shared directory for each domain to avoid traversal data exchange
SHARE=${HOME}/Share/${DOMAIN}
[ ! -d "${SHARE}" ] && mkdir -p "${SHARE}"


# SEC option is checked so let's set the option.
[ -n "${SEC}" ] && SEC="${sec_param}${SEC}"


# The certificate file is checked in check_certificate function
[ "${CERTIFICATE}" == "ignore" ]  \
	&& CERT_CONF="${ignore_cert_param}" \
	|| CERT_CONF="${cert_name_param}${CERTIFICATE}"


# The default is full screen
[ -z "${SCREEN_RESOLUTION}" ] &&  SCREEN_RESOLUTION="${fullscreen_param}"

# ---------------------------------------------------------------------
# Run it
# ---------------------------------------------------------------------

if [ ${DEBUG} ]
then
	cat <<EOF_DEBUG
/usr/bin/xfreerdp ${CERT_CONF}
		${network_param}
		${login_param}${USER}
		${domain_param}${DOMAIN}
		${SCREEN_RESOLUTION}
		${SEC}
		${title_param}"${SITE} ${DOMAIN} ${GROUP}"
		${share_param}Share:${SHARE}
		${clipboard}
		${host_param}${REMOTE_HOST}
EOF_DEBUG
else
/usr/bin/xfreerdp ${CERT_CONF} \ 
		${network_param} \
		${login_param}${LOGIN} \
		${domain_param}:${DOMAIN} \
		${SCREEN_RESOLUTION} \
		${SEC} \
		${title_param}"${SITE} ${DOMAIN} ${GROUP}"  \
		${share_param}Share:${SHARE} \
		${clipboard} \
		${host_param}${REMOTE_HOST}

fi


