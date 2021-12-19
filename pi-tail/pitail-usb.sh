#!/bin/sh


ip_bin="/usr/bin/ip"
ping_bin="/usr/bin/ping"
iptables_bin="/usr/bin/iptables"


pc_ip="192.168.42.129"
pitail_mac="3a:ea:66:54:bc:a1"
pitail_ip="192.168.42.254"

usage () {
	printf -- "USAGE: %s <up|down>\n\n\n" "$0"
}


do_pitail_up () {

	"${iptables_bin}" -I FORWARD 1 -i "${pitail_device_name}" -s "${pitail_ip}"/32 -p udp -m udp  -m comment --comment "PI-TAIL" -j ACCEPT
	"${iptables_bin}" -I FORWARD 1 -i "${pitail_device_name}" -s "${pitail_ip}"/32 -p tcp -m tcp  -m comment --comment "PI-TAIL" -j ACCEPT
	"${iptables_bin}" -I FORWARD 1 -o "${pitail_device_name}" -d "${pitail_ip}"/32 -m conntrack --ctstate RELATED,ESTABLISHED  -m comment --comment "PI-TAIL" -j ACCEPT

	"${iptables_bin}" -t nat -A POSTROUTING -s "${pitail_ip}"/32 -m comment --comment "PI-TAIL" -j MASQUERADE


	echo 1 > /proc/sys/net/ipv4/ip_forward

	"${ip_bin}" addr add "${pc_ip}"/24 dev "${pitail_device_name}"

	"${ip_bin}" link show "${pitail_device_name}"

	"${ping_bin}" -c 1 "${pitail_ip}"
}


do_pitail_down () {

	"${iptables_bin}" -D FORWARD -i "${pitail_device_name}" -s "${pitail_ip}"/32 -p udp -m udp  -m comment --comment "PI-TAIL" -j ACCEPT
	"${iptables_bin}" -D FORWARD -i "${pitail_device_name}" -s "${pitail_ip}"/32 -p tcp -m tcp  -m comment --comment "PI-TAIL" -j ACCEPT
	"${iptables_bin}" -D FORWARD -o "${pitail_device_name}" -d "${pitail_ip}"/32 -m conntrack --ctstate RELATED,ESTABLISHED  -m comment --comment "PI-TAIL" -j ACCEPT

	"${iptables_bin}" -t nat -D POSTROUTING -s "${pitail_ip}"/32 -m comment --comment "PI-TAIL" -j MASQUERADE


	echo 0 > /proc/sys/net/ipv4/ip_forward

	"${ip_bin}" addr del "${pc_ip}"/24 dev "${pitail_device_name}"

	"${ip_bin}" link show "${pitail_device_name}"

}



# Get pitail device
pitail_device_name="$(ip link show  | grep -B1 "${pitail_mac}" | head -1 | cut -d' ' -f2)"
pitail_device_name="${pitail_device_name//:/}"

[ -z "${pitail_device_name}" ] && { printf -- "[-] ERROR geting device from mac (%s)\n" "${pitail_mac}"; exit 1; }

action="${1}"

case "$action" in
	up) do_pitail_up ;;
  down) do_pitail_down ;;
     *)
	    printf -- "[-] unknown action %s\n" "$action"
		usage
		exit 1
	  ;;
esac





