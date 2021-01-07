#!/bin/bash
#
# Check inux recommandation.
#
# https://www.ssi.gouv.fr/guide/recommandations-de-securite-relatives-a-un-systeme-gnulinux/
#
#============================================================================
# VARS
#============================================================================

PGM="${PGM:-$(basename "$0")}"
# Variables
RESTORE='\033[0m'
RED='\033[00;31m'
GREEN='\033[00;32m'




#============================================================================
# FUNCTIONS
#============================================================================
error () {
	echo -e "${RED}[-] ${*}${RESTORE}"
}
warning () {
	echo -e "${RED}[!]${RESTORE} ${*}"
}

action () {
	echo -e "${GREEN}[+] ${*}${RESTORE}"
}

info() {
   printf -- "[-] %s" "${*}"
}


check_cmd() {

   if [ -x "${2}" ]
   then
     info " cmd ${2} ok\n"
   else
     error " cmd ${1} not found..."
     CHECK_ERROR=$(( CHECK_ERROR + 1 ))
   fi
}


usage () {

	cat <<EOF_USAGE

Usage: sudo ${PGM}

EOF_USAGE

}





check_files_rigts (){

	action "Remove mandatory setuid bits"
	info  "Remount / and /usr on rw mode\n"
	mount -orw,remount /
	mount -orw,remount /usr

	info "Remove the bit\n"
	chmod a-s \
		/bin/netreport \
		/usr/bin/chage \
		/usr/bin/chfn \
		/usr/bin/chsh \
		/usr/bin/rcp \
		/usr/bin/rlogin \
		/usr/bin/rsh \
		/usr/bin/screen \
		/usr/bin/wall \
		/usr/lib/openssh/ssh-keysign \
		/usr/bin/locate \
		/usr/bin/mail

	info "Remount back on ro mode\n"
	mount -oro,remount /usr
	mount -oro,remount /



	action "Searching current setuid bits prg"
	find / -type f -perm /6000 2>/dev/null | while read -r f
	do
		grep "^# $f" "$0"
	done

# /bin/netreport À désactiver.
# /usr/bin/chage À désactiver.
# /usr/bin/chfn À désactiver.
# /usr/bin/chsh À désactiver.
# /usr/bin/rcp Obsolète. À désactiver.
# /usr/bin/rlogin Obsolète. À désactiver.
# /usr/bin/rsh Obsolète. À désactiver.
# /usr/bin/screen À désactiver.
# /usr/bin/wall À désactiver.
# /usr/lib/openssh/ssh-keysign À désactiver.
# /bin/mount À désactiver, sauf si absolument nécessaire pour les utilisateurs.
# /bin/umount À désactiver, sauf si absolument nécessaire pour les utilisateurs.
# /sbin/mount.nfs4 À désactiver si NFSv4 est inutilisé.
# /sbin/mount.nfs À désactiver si NFSv2/3 est inutilisé.
# /sbin/umount.nfs4 À désactiver si NFSv4 est inutilisé.
# /sbin/umount.nfs À désactiver si NFSv2/3 est inutilisé.
# /usr/bin/gpasswd À désactiver si pas d’authentification de groupe.
# /bin/ping (IPv4) Retirer droit setuid, sauf si un programme le requiert pour du monitoring.
# /bin/ping6 (IPv6) Retirer droit setuid, sauf si un programme le requiert pour du monitoring.
# /usr/sbin/traceroute (IPv4) Retirer droit setuid, sauf si un programme le requiert pour du monitoring.
# /usr/sbin/traceroute6 (IPv6) Retirer droit setuid, sauf si un programme le requiert pour du monitoring.
# /bin/su Changement d’utilisateur. Ne pas désactiver.
# /usr/bin/sudo Changement d’utilisateur. Ne pas désactiver.
# /usr/bin/sudoedit Changement d’utilisateur. Ne pas désactiver.
# /sbin/unix_chkpwd Permet de vérifier le mot de passe utilisateur pour des programmes non root. À désactiver si inutilisé.
# /usr/bin/at À désactiver si atd n’est pas utilisé.
# /usr/bin/crontab À désactiver si cron n’est pas requis.
# /usr/bin/fusermount À désactiver sauf si des utilisateurs doivent monter des partitions FUSE.
# /usr/bin/locate À désactiver. Remplacer par mlocate et slocate.
# /usr/bin/mail À désactiver. Utiliser un mailer local comme ssmtp.
# /usr/bin/newgrp À désactiver si pas d’authentification de groupe.
# /usr/bin/passwd À désactiver, sauf si des utilisateurs non root doivent pouvoir changer leur mot de passe.
# /usr/bin/pkexec À désactiver si PolicyKit n’est pas utilisé.
# /usr/bin/procmail À désactiver sauf si procmail est requis.
# /usr/bin/X À désactiver sauf si le serveur X est requis.
# /usr/lib/dbus-1.0/dbus-daemon-launch-helper À désactiver quand D-BUS n’est pas utilisé.
# /usr/lib/pt_chown À désactiver (permet de changer le propriétaire des PTY avant l’ex- istence de devfs).
# /usr/libexec/utempter/utempter À désactiver si le profil utempter SELinux n’est pas utilisé.
# /usr/sbin/exim4 À désactiver si Exim n’est pas utilisé.
# /usr/sbin/suexec À désactiver si le suexec Apache n’est pas utilisé.


	# Many files in docker overlay are in error.
	# TODO: add an option to escape docker
	action "Search no{user,group} files"
	find / -type f \( -nouser -o -nogroup \) -ls 2>/dev/null \
		| grep -v /var/lib/docker/


	action "Search openbar dirs"
	info "Dirs without sticky bit\n"
	find / -type d \( -perm -0002 -a \! -perm -1000 \) -ls 2>/dev/null

	info "non root dirs\n"
	find / -type d -perm -0002 -a \! -uid 0 -ls 2>/dev/null



	info "Files\n"
	find / -type f -perm -0002 -ls 2>/dev/null
	# This are 666 (why) ??
	# man 5 /proc
	# /proc/21526/task/21526/attr/current
	# /proc/21526/task/21526/attr/exec
	# /proc/21526/task/21526/attr/fscreate
	# /proc/21526/task/21526/attr/keycreate
	# /proc/21526/task/21526/attr/sockcreate
	# /proc/21526/task/21526/attr/smack/current
	# /proc/21526/attr/current
	# /proc/21526/attr/exec
	# /proc/21526/attr/fscreate
	# /proc/21526/attr/keycreate
	# /proc/21526/attr/sockcreate
	# /proc/21526/attr/smack/current
	# /proc/21526/timerslack_ns

}

check_sockets () {

	action "Check socks"

	info "Local sockets\n"
	/usr/bin/ss -xp

	info "Shared memory\n"
	/usr/bin/ipcs

	info "Shared rights in /dev/shm \n"
	/bin/ls -al /dev/shm


    # lsof is fine to
}

audit () {
	cat <<EOF_RULES
# Exécution de insmod , rmmod et modprobe
-w /sbin/insmod -p x
-w /sbin/modprobe -p x
-w /sbin/rmmod -p x
# Journaliser les modifications dans /etc/
-w /etc/ -p wa
# Surveillance de montage/démontage
-a exit ,always -S mount -S umount2
# Appels de syscalls x86 suspects
-a exit ,always -S ioperm -S modify_ldt
# Appels de syscalls qui doivent être rares et surveillés de près
-a exit ,always -S get_kernel_syms -S ptrace
-a exit ,always -S prctl
# Rajout du monitoring pour la création ou suppression de fichiers
# Ces règles peuvent avoir des conséquences importantes sur les
# performances du système
-a exit ,always -F arch=b64 -S unlink -S rmdir -S rename
-a exit ,always -F arch=b64 -S creat -S open -S openat -F exit=-EACCESS
-a exit ,always -F arch=b64 -S truncate -S ftruncate -F exit=-EACCESS
# Verrouillage de la configuration de auditd
-e 2

EOF_RULES
}

#============================================================================
# MAIN
#============================================================================


if [ $(id -u ) -ne 0 ]
then
	error "Must be root to run the this prg"
	usage
	exit 1
fi



check_sockets


info "\n"
