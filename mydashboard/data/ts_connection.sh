#!/bin/sh

COLOR=${1}
TSNAME=${2}
PASSWDGRP_PREFIX="${3}"
DOMAIN=${4}
SEC=${5:-""}

PARTAGE=${HOME}Partage/${DOMAIN}

[ -n "${SEC}" ] && SEC="--sec ${SEC}"

LOGIN="a-${COLOR}-$(id -u -n)"

/usr/bin/xfreerdp --ignore-certificate -x l -u ${LOGIN} -g 90% ${SEC} -d ${DOMAIN}  -T "${DOMAIN} ${COLOR}"  --plugin cliprdr --plugin rdpsnd --plugin rdpdr --data disk:Share:${PARTAGE} -- ${TSNAME}


