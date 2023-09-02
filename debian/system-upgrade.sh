#!/bin/bash
#
set -o errexit
set -o nounset
#set -o pipefail


logfilename="/dev/shm/upgrade.log"

info () {
	printf -- "[*] %s\n" "$@"
	printf -- "[*] %s\n" "$@" >> "$logfilename"
}

action () {
	printf -- "[+] %s\n" "$@"
	printf -- "[+] %s\n" "$@" >> "$logfilename"
}

error () {
	printf -- "[-] %s\n" "$@"
	printf -- "[-] %s\n" "$@" >> "$logfilename"
}


end_process () {
	info "$(date --rfc-3339=seconds) - End process"
	printf -- "See more logs in %s\n" "$logfilename"
}
trap end_process EXIT



info "$(date --rfc-3339=seconds) - begin process"

apt update >> "$logfilename" 2>&1 || {
	error "Updating db"
	cat "$logfilename"
	exit 1
}

nbpkg="$(LANG=C  apt list --upgradable --quiet 2>/dev/null | grep -v Listing...  | wc -l )"

[ $nbpkg == 0 ] && {
	info "System up to date"
	exit 0
}

info "$nbpkg pkg(s) must be upgraded"
LANG=C  apt list --upgradable --quiet 2>/dev/null | grep -v Listing...

action "Running upgrade"
apt  upgrade --auto-remove --assume-yes >> "$logfilename" 2>&1 || {
	error "Upgrade fails"
	cat "$logfilename"
	exit 1
}

action "Rebooting"

/usr/sbin/reboot




