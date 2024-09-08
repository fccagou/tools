#!/usr/bin/bash
set -eu
set -o pipefail


[ "$(id -u)" == "0" ] || {
	printf -- "[-] Ce script ajoute des comptes utilisaters,\n     il DOIT être exécuté avec les droits root\n\n"
    exit 1
}


set +u
ROOTLESSDIR="${ROOTLESSDIR:-docker-rootless}"
set -u

NEWUSER="${NEWUSER:-$1}"
COMMENT="${COMMENT:-$2}"

useradd --system --comment "$COMMENT" --create-home "$NEWUSER"

userenv="$ROOTLESSDIR"/user.env

[ -f "$userenv" ] || {
  # Ficher d'env
  cat > "$userenv" <<EOF
export XDG_RUNTIME_DIR=/run/user/"\$(id -u)"
export DBUS_SESSION_BUS_ADDRESS=unix:path="\${XDG_RUNTIME_DIR}"/bus
export DOCKER_HOST=unix://"\${XDG_RUNTIME_DIR}"/docker.sock
export PATH="$ROOTLESSDIR"/bin:"\$PATH"
EOF

  sha256sum "$userenv" >> sha256sum.txt
}


newuserhomedir="$(getent passwd "$NEWUSER" | cut -d: -f6)"

grep -q "$userenv" "$newuserhomedir"/.bash_profile \
|| echo "[[ -f $userenv ]] && . $userenv" >> "$newuserhomedir"/.bash_profile

loginctl enable-linger "$NEWUSER"


# Get last and add 1 for next value
usersubuid="$(sort -t: -k2 /etc/subuid |tail -1 |awk -F: '{ print $2+$3+1 }')"
usersubgid="$(sort -t: -k2 /etc/subgid |tail -1 |awk -F: '{ print $2+$3+1 }')"

[ -n "$usersubuid" ] || usersubuid=100000
[ -n "$usersubgid" ] || usersubgid=100000

# Add subuid entry for NEWUSER
grep -q "^${NEWUSER}:" /etc/subuid || echo "$NEWUSER:$usersubuid:65536" >> /etc/subuid
# Add subgid entry for NEWUSER
grep -q "^${NEWUSER}:" /etc/subgid || echo "$NEWUSER:$usersubgid:65536" >> /etc/subgid

su - "$NEWUSER" -c "USER=$NEWUSER; sleep 3; dockerd-rootless-setuptool.sh install --skip-iptables && docker images"

