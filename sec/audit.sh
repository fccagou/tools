#!/bin/sh

collect_file=""


info () {

	printf -- "%s [INFO] %s\n" "$(date +%s)" "${@}"
}

run () {
	cmd="${1// *}"
	full_path="$( (alias | declare -f) | /usr/bin/which --tty-only --read-alias --read-functions --show-tilde --show-dot "${cmd}" 2>/dev/null)"
	if [ -z "${full_path}" ]
	then
		info "Running ${*} (not found)"
	else
		info "Running ${full_path} ${*}"
		${@} > ${collect_file} 2>&1
	fi
}


# -------------------------------------------------------------------
collect_users_groups () {
	info 'launching collector "users_groups"'
	# 1601038141 [INFO] collector users_groups has pid 18088
	# 1601038141 [INFO] context master process has PID 18087
	getent group  > "${collect_file}" 2>&1
	info 'finished running collector "users_groups"'
}


# -------------------------------------------------------------------
collect_users_configuration () {
	info 'launching collector "configuration"'
	# 1601038142 [INFO] collector configuration has pid 18090

	run "sysctl -a"
	run "uname --all"
	run "lsb_release --all"
	run "initctl list"
	info 'inished running collector "configuration"'
}


# -------------------------------------------------------------------
collect_docker () {
	info 'launching collector "docker"'
	# 1601038143 [INFO] collector docker has pid 18120
	run "docker version"
	run "docker info"
	run "docker container ls -a"
	run "docker images -a"
	run "docker volume ls"
	run "docker network ls"
	info 'finished running collector "docker"'
}

# -------------------------------------------------------------------
collect_hardware () {
	info 'launching collector "hardware"'
	# 1601038144 [INFO] collector hardware has pid 18131
	run "lspci -v"
	run "lspci -t"
	run "lspci -nnvvxxx"
	run "lsusb -t"
	run "lsusb -v"
	info 'finished running collector "hardware"'
}


# -------------------------------------------------------------------
collect_network () {

	info 'launching collector "network"'
	# 1601038146 [INFO] collector network has pid 18142
	run "ip neigh show"
	run "ip addr show"
	run "ip link show"
	run "ip -4 route show"
	run "ip -6 route show"
	run "ip -4 route show table all"
	run "ip -6 route show table all"
	run "ip -4 rule"
	run "ip -6 rule"
	run "ss --numeric --all --processes"
	run "ss --numeric --all --processes --tcp --udp --extend --listening"
	run "arp -n"
	run "ifconfig -a"
	run "route -n"
	run "route -6n"
	run "route -n -A inet6"
	run "netstat --numeric --all --program"
	run "netstat --numeric --all --route"
	run "netstat --numeric --all --program --tcp --udp --extend --listening"
	run "brctl show"
	run "lsof -i -n"
	run "iptables-save "
	run "ip6tables-save "
	run "nft -an list ruleset"
	run "iptables -t filter --list --numeric --verbose"
	run "ip6tables -t filter --list --numeric --verbose"
	run "iptables -t nat --list --numeric --verbose"
	run "ip6tables -t nat --list --numeric --verbose"
	run "iptables -t mangle --list --numeric --verbose"
	run "ip6tables -t mangle --list --numeric --verbose"
	run "iptables -t raw --list --numeric --verbose"
	run "ip6tables -t raw --list --numeric --verbose"
	run "iptables -t security --list --numeric --verbose"
	run "ip6tables -t security --list --numeric --verbose"
	info 'finished running collector "network"'
}


# -------------------------------------------------------------------
collect_rpc () {
	info 'launching collector "rpc"'
	# 1601038148 [INFO] collector rpc has pid 18180
	run "rpcinfo -p"
	# CA BLOQUE run "showmount "
	info 'finished running collector "rpc"'
}

# -------------------------------------------------------------------
collect_selinux () {
	info 'launching collector "selinux"'
	# 1601038149 [INFO] collector selinux has pid 18183
	run "sestatus "
	run "getsebool -a"
	run "semodule -l"
	run "semanage login -l"
	run "semanage user -l"
	run "semanage boolean -l"
	run "semanage module -l"
	run "semanage permissive -l"
	run "semanage fcontext -l"
	run "semanage port -l"
	run "semanage interface -l"
	run "semanage node -l"
	run "semanage export"
	info 'finished running collector "selinux"'
}

# -------------------------------------------------------------------
collect_software () {
	info 'launching collector "software"'
	# 1601038187 [INFO] collector software has pid 18240
	run "dpkg --list"
	run "rpm --query --all"
	run "rpm --query --all --last"
	info 'finished running collector "software"'
}


# -------------------------------------------------------------------
collect_sudoers () {
	info 'launching collector "sudoers_executables"'
	# 1601038196 [INFO] collector sudoers_executables has pid 18256
	if [ -f '/etc/sudoers' ]
	then
		# 1601038196 [INFO] parsing sudoers configuration
		# 1601038196 [INFO] collecting sudoers configuration
		info 'collected /etc/sudoers as a sudoers configuration'
		# 1601038196 [INFO] collecting executables mentioned in sudoers configuration
	fi
	info 'finished running collector "sudoers_executables"'
}

# -------------------------------------------------------------------
collect_state () {
	info 'launching collector "state"'
	# 1601038197 [INFO] collector state has pid 18258
	run "sh -c set"
	run "date "
	run "date --rfc-2822"
	run "lsof "
	run "lsof -v"
	run "dmesg "
	run "ps aguxwww"
	run "ps aguxwwwZ"
	run "ps wl"
	run "ps -eo pid,ppid,user,ipcns,mntns,netns,pidns,userns,utsns,cgroup"
	run "ps -efH"
	run "last -a"
	run "last -ai"
	run "lastlog "
	run "df --all --human-readable"
	run "uptime "
	run "free -m"
	run "swapon --summary"
	run "ipcs "
	info 'finished running collector "state"'
}


# -------------------------------------------------------------------
collect_systemd () {
	info 'launching collector "systemd"'
	# 1601038218 [INFO] collector systemd has pid 18296
	run "hostnamectl status"
	run "systemctl list-units -all --full --recursive"
	run "systemctl list-unit-files -all"
	run "systemctl list-sockets --all --show-type"
	run "systemctl list-timers --all --full"
	run "systemctl list-machines --all"
	run "systemctl list-jobs --all --full"
	run "systemctl list-dependencies"
	run "systemd-delta "
	run "journalctl --header"
	run "journalctl --disk-usage"
	run "journalctl --all --catalog --output=verbose -S @0"
	run "journalctl --all --catalog --output=cat -S @0"

	for type in automount mount path scope service slice socket target timer
	do
		for service in $(systemctl list-units --type "${type}" | grep "${type}" | awk '{ print $1 }')
		do

			run "systemctl cat -- ${service}"
			run "systemctl show -- ${service}"

		done
	done
	info 'finished running collector "systemd"'
}

# -------------------------------------------------------------------
collect_apache_configuration () {
	info 'launching collector "apache_configuration"'
	# 1601038240 [INFO] collector apache_configuration has pid 18984

	apache_files="/etc/apache2/apache2.conf
/etc/apache2/apache2.conf
/etc/apache2/apache2.conf
/etc/apache2/apache2.conf
/etc/apache2/apache2.conf
/etc/httpd/conf/httpd.conf
/etc/httpd/conf/httpd.conf
/etc/httpd/conf/httpd.conf
/etc/httpd/conf/httpd.conf
/etc/httpd/conf/httpd.conf
/usr/local/apache2/conf/httpd.conf
/usr/local/apache2/conf/httpd.conf
/usr/local/apache2/conf/httpd.conf
/usr/local/apache2/conf/httpd.conf
/usr/local/apache2/conf/httpd.conf
/usr/local/etc/apache2/httpd.conf
/usr/local/etc/apache2/httpd.conf
/usr/local/etc/apache2/httpd.conf
/usr/local/etc/apache2/httpd.conf
/usr/local/etc/apache2/httpd.conf
/etc/httpd/httpd.conf
/etc/httpd/httpd.conf
/etc/httpd/httpd.conf
/etc/httpd/httpd.conf
/etc/httpd/httpd.conf
"

	for f in ${apache_files}
	do
		if [ ! -f "${f}" ]
		then
			printf -- "[INFO] failed to read potential apache configuration file %s\n" "${f}"
		else
			cat "${f}" > "${collect_file}" 2>&1
		fi
	done
	info 'finished running collector "apache_configuration"'
}

# -------------------------------------------------------------------
collect_mount_namespace () {
	pid="${1}"
    namespace="${2}"

    info "Collecting mount namespace %s from PID %s" "${namespace}" "${pid}"
	run "findmnt --task ${pid}"
}

# -------------------------------------------------------------------
collect_filesystem () {
	info 'launching collector "filesystem"'
	# 1601038241 [INFO] collector filesystem has pid 18986
	run "lsblk "
	run "lsblk --output-all"
	run "mount --verbose"
	run "findmnt "
	# 1601038242 [INFO] Walking the filesystem from 44 mount points
	# 1601038242 [INFO] Walking "/sys" (sysfs)
	# 1601038249 [INFO] Walking "/proc" (proc)

	collect_network_namespace 1
	collect_mount_namespace 1

	# TODO: trouover à quel process correspond ce pid
	# 1601038253 [INFO] Collecting mount namespace 4026531856 from PID 28
	# run "findmnt --task 28"

	# TODO: trouver à quel process correspond ce pid
	# collect_network_namespace 925

	# TODO: quelle list ?
	pid_list=""

	for pid in $pid_list
	do
		collect_mount_namespace "${pid}"
	done

	# 1601038303 [INFO] Looking at files metadata, currently at "/proc/5239/task/5239/net/stat/arp_cache", 160636 files since last status line
	# 1601038327 [INFO] Walking "/dev" (devtmpfs)
	# 1601038328 [INFO] Walking "/sys/kernel/security" (securityfs)
	# 1601038328 [INFO] Walking "/dev/shm" (tmpfs)
	# 1601038328 [INFO] Walking "/dev/pts" (devpts)
	# 1601038328 [INFO] Walking "/run" (tmpfs)
	# 1601038328 [INFO] Walking "/sys/fs/cgroup" (tmpfs)
	# 1601038328 [INFO] Walking "/sys/fs/cgroup/systemd" (cgroup)
	# 1601038328 [INFO] Walking "/sys/fs/pstore" (pstore)
	# 1601038328 [INFO] Walking "/sys/fs/cgroup/pids" (cgroup)
	# 1601038328 [INFO] Walking "/sys/fs/cgroup/hugetlb" (cgroup)
	# 1601038328 [INFO] Walking "/sys/fs/cgroup/freezer" (cgroup)
	# 1601038328 [INFO] Walking "/sys/fs/cgroup/cpuset" (cgroup)
	# 1601038328 [INFO] Walking "/sys/fs/cgroup/perf_event" (cgroup)
	# 1601038328 [INFO] Walking "/sys/fs/cgroup/cpu,cpuacct" (cgroup)
	# 1601038328 [INFO] Walking "/sys/fs/cgroup/net_cls,net_prio" (cgroup)
	# 1601038328 [INFO] Walking "/sys/fs/cgroup/devices" (cgroup)
	# 1601038328 [INFO] Walking "/sys/fs/cgroup/memory" (cgroup)
	# 1601038328 [INFO] Walking "/sys/fs/cgroup/blkio" (cgroup)
	# 1601038328 [INFO] Walking "/sys/kernel/config" (configfs)
	# 1601038328 [INFO] Walking "/" (ext4)
	# 1601038344 [INFO] Walking "/usr" (ext4)
	# 1601038364 [INFO] Looking at files metadata, currently at "/usr/lib64/gedit/plugins/quickopen/__init__.pyc", 176261 files since last status line
	# 1601038364 [INFO] Walking "/sys/fs/selinux" (selinuxfs)
	# 1601038365 [INFO] Walking "/sys/kernel/debug" (debugfs)
	# 1601038367 [INFO] Walking "/dev/mqueue" (mqueue)
	# 1601038367 [INFO] Walking "/dev/hugepages" (hugetlbfs)
	# 1601038367 [INFO] Walking "/boot" (ext4)
	# 1601038367 [INFO] Walking "/boot/efi" (vfat)
	# 1601038367 [INFO] Walking "/var" (ext4)
	# 1601038371 [INFO] Walking "/var/tmp" (ext4)
	# 1601038371 [INFO] Walking "/var/log" (ext4)
	# 1601038380 [INFO] Walking "/tmp" (ext4)
	# 1601038380 [INFO] Walking "/opt" (ext4)
	# 1601038380 [INFO] Walking "/var/lib/nfs/rpc_pipefs" (rpc_pipefs)
	# 1601038380 [INFO] Walking "/run/user/16001" (tmpfs)
	# 1601038380 [INFO] Walking "/proc/sys/fs/binfmt_misc" (binfmt_misc)
	# 1601038380 [INFO] finished running collector "filesystem"
}


# -------------------------------------------------------------------
collect_homedir () {
	info 'launching collector "home_directories"'
	#info 'collector home_directories has pid 19207

	getent passwd | cut -d: -f1,2,6 | while IFS=':' read -r login uid homedir
	do
		info "Collecting files from the home of ${login} (uid=${uid}): ${homedir}"
	done

	info 'finished running collector "home_directories"'
}

# -------------------------------------------------------------------
collect_cron () {
	# 1601038384 [INFO] collector cron has pid 19212
	for login in $( getent passwd | cut -d: -f1)
	do
		run "crontab -lu ${login}"
	done
}


# -------------------------------------------------------------------
collect_network_namespace () {

	pid="${1}"
    namespace="${2}"

    info "Collecting network namespace ${namespace} from PID ${pid}"

	run "nsenter --target ${pid} --net ip neigh show"
	run "nsenter --target ${pid} --net ip addr show"
	run "nsenter --target ${pid} --net ip link show"
	run "nsenter --target ${pid} --net ip -4 route show"
	run "nsenter --target ${pid} --net ip -6 route show"
	run "nsenter --target ${pid} --net ip -4 route show table all"
	run "nsenter --target ${pid} --net ip -6 route show table all"
	run "nsenter --target ${pid} --net ip -4 rule"
	run "nsenter --target ${pid} --net ip -6 rule"
	run "nsenter --target ${pid} --net ss --numeric --all --processes"
	run "nsenter --target ${pid} --net ss --numeric --all --processes --tcp --udp --extend --listening"
	run "nsenter --target ${pid} --net arp -n"
	run "nsenter --target ${pid} --net ifconfig -a"
	run "nsenter --target ${pid} --net route -n"
	run "nsenter --target ${pid} --net route -6n"
	run "nsenter --target ${pid} --net netstat --numeric --all --program"
	run "nsenter --target ${pid} --net netstat --numeric --all --route"
	run "nsenter --target ${pid} --net netstat --numeric --all --program --tcp --udp --extend --listening"
	run "nsenter --target ${pid} --net brctl show"
	run "nsenter --target ${pid} --net iptables-save"
	run "nsenter --target ${pid} --net ip6tables-save"
	run "nsenter --target ${pid} --net nft list ruleset -an"
	run "nsenter --target ${pid} --net iptables -t filter --list --numeric --verbose"
	run "nsenter --target ${pid} --net ip6tables -t filter --list --numeric --verbose"
	run "nsenter --target ${pid} --net iptables -t nat --list --numeric --verbose"
	run "nsenter --target ${pid} --net ip6tables -t nat --list --numeric --verbose"
	run "nsenter --target ${pid} --net iptables -t mangle --list --numeric --verbose"
	run "nsenter --target ${pid} --net ip6tables -t mangle --list --numeric --verbose"
	run "nsenter --target ${pid} --net iptables -t raw --list --numeric --verbose"
	run "nsenter --target ${pid} --net ip6tables -t raw --list --numeric --verbose"
	run "nsenter --target ${pid} --net iptables -t security --list --numeric --verbose"
	run "nsenter --target ${pid} --net ip6tables -t security --list --numeric --verbose"

}




# -------------------------------------------------------------------
# M A I N
# -------------------------------------------------------------------

collect_log_dir="/var/tmp/collect"

if [ ! -d "${collect_log_dir}" ]
then
	mkdir "${collect_log_dir}"
	if [ ! -d "${collect_log_dir}" ]
	then
		printf -- "[-] error creating collect dir %s\n" "${collect_log_dir}"
		exit 1
	fi
fi



info "Launched ${0}"
# 1601038141 [INFO] Collect version: 0.3-0-g2c6e2929e30bc2afa8fc1458d64a5d29317a5fb0
info "Hostname: $(hostname)"
info "Running with UID $(id -u)"
infos="$(ps -o uid,euid $$ | awk '{ print $2; }' | tail -1)"
info "Running with UID ${infos// *} and EUID ${infos//* }"
info "main process has PID %s" "$$"
# 1601038141 [INFO] UID has been changed to 0

collectors="users_groups
users_configuration
docker
hardware
network
rpc
selinux
software
sudoers
state
systemd
apache_configuration
filesystem
homedir
cron"

for c in $collectors
do
	collect_file="${collect_log_dir}/${c}.log"
	eval "collect_${c}"
done

# collect_users_groups > /var/tmp/users_groups.log 2>&1
# collect_users_configuration
# collect_docker
# collect_hardware
# collect_network
# collect_rpc
# collect_selinux
# collect_software
# collect_sudoers
# collect_state
# collect_systemd
# collect_apache_configuration
# collect_filesystem
# collect_homedir
# collect_cron

info 'finished running collectors'
