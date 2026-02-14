#!/usr/bin/bash
# vim: ts=4 sw=4 expandtab
#
set -euo pipefail


LIBVIRT_DEFAULT_URI="${LIBVIRT_DEFAULT_URI:-system}"
export LIBVIRT_DEFAULT_URI


VIRT_NETWORK_NAME="${VIRT_NETWORK_NAME:-kube}"


KUBE_HOSTS="${KUBE_HOSTS:-$(LANG=C virsh net-dhcp-leases --network kube | awk '{print $6 }' | grep -vE '^(IP|)$')}"

_VIRSH_FITER="${KUBE_HOSTS// /|}"


header() {
    local action
    action="$1"

    echo ""
    echo "------[MYKUBE]------------------------------"
    echo ""
    echo "   VIRT_NETWORK_NAME=${VIRT_NETWORK_NAME}"
    echo "   LIBVIRT_DEFAULT_URI=${LIBVIRT_DEFAULT_URI}"
    echo ""
    echo "--($action)-------------"
    echo ""
}

usage() {
    echo "usage: $0 up|down|status|help"
    echo ""
}


cluster_up () {
    header "Démarage"

    for h in $(virsh list --state-shutoff --name | grep -E "${_VIRSH_FITER}"); do
        virsh start --domain "$h"
    done

}

cluster_down () {
    header "Arrêt"
    for h in $(virsh list --state-running --name | grep -E "${_VIRSH_FITER}"); do
        virsh shutdown --domain "$h"
    done
}

cluster_status () {
    header "status"
    virsh list --all | grep -E "${_VIRSH_FITER}"
}

if (( $# == 0 )); then
    cluster_status
    exit $?
fi

while (( $# > 0 )); do
    case "$1" in
        up) cluster_up ;;
        down) cluster_down ;;
        status) cluster_status ;;
        help|-h|--help)
            usage
            exit 0
            ;;
        *)
            echo "[ERREUR] - Parametre inconnu ${@}"
            usage
            exit 1
            ;;
    esac
    shift
done


