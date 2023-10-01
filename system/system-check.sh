#!/usr/bin/bash
#
# Script for host checking.
#


set -o errexit
set -o nounset
set -o pipefail



info () {
	printf -- "[*] %s\n" "$@"
}

action () {
	printf -- "[+] %s\n" "$@"
}

error () {
	printf -- "[-] %s\n" "$@"
}



get_if_list () {
	# /usr/bin/ip -br link show | awk '{print $1 }'
	/usr/bin/ls -1 /sys/class/net/
}

get_if_addr () {
    # /usr/bin/ip -br address show "${1//@*}" | sed 's/^.*[UP|DOWN] *//'
	cat /sys/class/net/"$1"/address
}

get_if_status () {
    # /usr/bin/ip -br address show "${1//@*}" | awk '{print $2}'
	#cat /sys/class/net/"$1"/carrier
	cat /sys/class/net/"$1"/operstate
}

check_network () {
	declare -A mynet

	for i in $(get_if_list)
	do
		mynet['if']+=" $i"
		mynet["${i}_status"]="$(get_if_status "$i")"
		mynet["${i}_addr"]="$(get_if_addr "$i")"
	done
	for i in ${mynet['if']}
	do
		printf -- "[%s] %s (%s)\n" \
			"${mynet["${i}_status"]}" \
			"$i" \
			"${mynet["${i}_addr"]}" \
			#
	done | sort

}


check_network




