#!/bin/sh

if [ "${1}" = "-d" ]
then
	BACKUPDIR="${2}"
	shift; shift;
else
	BACKUPDIR="."
fi

if [ "${1}" = "all" ]
then
	DOMAINS="$(virsh list --all --name | grep -v '^$' )"
else
	DOMAINS="${@}"
fi

for name in ${DOMAINS}
do
	DESTDIR="${BACKUPDIR}/${name}"
	printf -- "[+] domain $name\n"
	if [ ! -d  "${DESTDIR}" ]
	then
		printf -- "[-] creating backup dir ${DESTDIR}\n"
		mkdir -p "${DESTDIR}"
	fi
	printf -- "[-] dump conf to ${DESTDIR}/$name.xml.gz\n"
	virsh dumpxml $name | gzip -c >  "${DESTDIR}/$name.xml.gz"	
	dd=$(zcat "${DESTDIR}/$name.xml.gz" | egrep 'source (file|dev)' | grep -v iso | cut -d\' -f2 )
	if [ -z "${dd}" ]
	then
		printf -- "[-] no dd found\n"
	else
		ddname="${dd##*/}"
		printf -- "[-] backup dd to ${DESTDIR}/${ddname}.gz\n"
		gzip -c ${dd} | pv -p > ${DESTDIR}/${ddname}.gz
	fi
done

