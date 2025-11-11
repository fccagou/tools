#!/usr/bin/env bash
# Description: gère le forward de port vers une vm à l'aide de nftables
# Usage: sudo ./libvirt-portfw.sh <start|stop> <VM_NAME> [PORTS]
# Example: sudo ./libvirt-portfw.sh start debian-test 22,80,8080
#

set -euo pipefail

ACTION=${1:-}
VM_NAME=${2:-}
PORTS=${3:-22}
NET_NAME="default"
TABLE="ip ctf"

need_create=no


usage () {
	echo "Usage: $0 help | status   |  <start|stop> <VM_NAME> [ports]"
}

status () {
	 nft -a list table $TABLE 2>/dev/null || echo "Table $TABLE absente"
	 nft -a list table ip libvirt_network | grep 666
}

if [[ "$ACTION" =~ "help" ]]; then
	usage
	exit 0
fi

if [[ "$ACTION" == "status" ]]; then
	status
	exit 0
fi



if [[ -z "$ACTION" || -z "$VM_NAME" ]]; then
	usage
    exit 1
fi



# Interface externe (celle avec la route par défaut)
EXT_IF=$(ip route | awk '/default/ {print $5; exit}')
if [[ -z "$EXT_IF" ]]; then
    echo "❌ Impossible de détecter l’interface externe"
    exit 1
fi



# Récupère l'IP de la VM
VM_IP=$(virsh --quiet domifaddr --domain "$VM_NAME"  2>/dev/null | awk '/ipv4/ {print $4}' | cut -d/ -f1 | head -n1)
if [[ -z "$VM_IP" ]]; then
    VM_MAC=$(virsh domiflist "$VM_NAME" | awk '/network/ {print $5; exit}')
    VM_IP=$(virsh net-dhcp-leases "$NET_NAME" | awk -v mac="$VM_MAC" '$0 ~ mac {print $5}' | cut -d/ -f1 | head -n1)
fi

if [[ -z "$VM_IP" ]]; then
    echo "❌ Impossible de déterminer l’adresse IP de la VM '$VM_NAME'"
    exit 1
fi


IFS=',' read -r -a PORT_LIST <<< "$PORTS"

stop_forward () {
    handle="$(nft -a list chain ip libvirt_network guest_input | grep "CTF from prerouting" | cut -d\# -f2 || echo "")"
    if [ -n "$handle" ]; then
		echo "🧹 Suppression règle accept mark dans ip libvirt_network guest_input ($handle)"
    	nft delete rule ip libvirt_network guest_input $handle
    fi

	if nft list tables | grep -q "^table ${TABLE}$"; then
        echo "🧹 Suppression table $TABLE"
    	nft delete table $TABLE
	fi
    echo "✅ Redirections supprimées."
}




start_forward () {

	echo "Création de la table $TABLE"
	nft add table $TABLE
	echo "⚙️  Création chain prerouting dans la table $TABLE"
	nft add chain $TABLE prerouting '{ type nat hook prerouting priority dstnat; policy accept; }'

    echo "⚙️  Ajout des redirections vers $VM_NAME ($VM_IP)"
	for port in "${PORT_LIST[@]}"; do
        echo " - TCP port $port"
		nft add rule  $TABLE prerouting "iif ${EXT_IF} counter tcp dport $port meta mark set 0x666 dnat ip to ${VM_IP}:$port comment \"CTF forward port $port\"; "
	done
    echo "⚙️  Ajout interdiction de sortie vers port 22 pour $VM_NAME ($VM_IP)"
	nft add rule  $TABLE prerouting "iif virbr0 counter ip saddr ${VM_IP} ct state { 0x2, 0x4 } accept comment \"CTF allow tracked connections\";"
	nft add rule  $TABLE prerouting "iif virbr0 counter ip saddr ${VM_IP} drop comment \"CTF ALERTE tentative sortie 22\"; "

#     echo "⚙️  Ajout des redirections vers $VM_NAME ($VM_IP)"
# 	nft add chain  $TABLE forward '{ type filter hook forward priority filter; policy accept; }'
# 	nft add rule $TABLE forward iif ${EXT_IF} counter meta mark set 0x666 comment '"CTF forward to VM";'

	echo "⚙️  Ajout règle accept mark dans ip libvirt_network guest_input"
	nft insert rule ip libvirt_network guest_input 'oif virbr0 counter meta mark 0x666 accept comment "CTF from prerouting";'
    echo "✅ Redirections Mise en place."
}


case "$ACTION" in
    start) start_forward ;;
    stop)  stop_forward ;;
	status) status;;
	*) usage ;  exit 1 ;;
esac

