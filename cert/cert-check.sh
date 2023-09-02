#!/usr/bin/bash
#

set -o pipefail
set -o nounset
set -o errexit

info () {
        printf -- "[*] %s\n" "$@"
        #printf -- "[*] %s\n" "$@" >> "$logfilename"
}

action () {
        printf -- "[+] %s\n" "$@"
        #printf -- "[+] %s\n" "$@" >> "$logfilename"
}

error () {
        printf -- "[-] %s\n" "$@"
        #printf -- "[-] %s\n" "$@" >> "$logfilename"
}

usage () {
	cat <<EOF_USAGE
Usage: $0 domain.name

EXAMPLE:

    $0 gitlab.com

EOF_USAGE
}

[ "$#" != 0 ] || {
	error "needs a parameter"
	usage
    exit 1
}

DOMAIN="$1"

certinfo="$(true | openssl s_client -4 -servername "$DOMAIN" -connect "$DOMAIN":443  2>/dev/null | openssl x509 -noout -dates | grep notAfter | sed 's/.*=//')"

certdate="$(date -d "$certinfo" +%s )"

now="$(date +%s )"

if [ "$certdate" -gt "$now" ]
then
	info "Certificate will expire in $(( (certdate - now) / 3600 / 24  )) day(s) ($certinfo)"
	exit 0
fi

if [ "$certdate" = "$now" ]
then
	warning "Certificate expires today"
	exit 2
fi

error "Certificat expires $(( (now - certdate) / 3600 / 24 )) day(s) ($certinfo)"
exit 1



