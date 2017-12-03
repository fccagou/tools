#!/bin/sh

BTDEVICE=${BTDEVICE:-"undef"}
KODISRV=${KODISRV:-"127.0.0.1:8080"}

if [ "${BTDEVICE}" == "undef" ]
then
	printf -- '[-] ERROR, BLUETOOTH Device not set (var BTDEVICE)\n'
	exit 1
fi


while true
do

	if [ -z "$(echo device  | bluetoothctl 2>&1 | grep ${BTDEVICE})" ]
	then
		# Device absent
		printf -- "[-] Device ${BTDEVICE} absent, waiting 15 sec before next check\n"
		sleep 15
	else
		if [ -z "$(echo "info ${BTDEVICE}" | bluetoothctl 2>&1 | grep 'Connected: yes')" ]
		then
			# Is kodi playing ?
			if [ -n "$(curl -s -d '{"jsonrpc":"2.0", "method": "Player.GetProperties", "params": { "properties": [ "speed" ], "playerid": 0 }, "id": 1}' -H "Content-Type: application/json" -X POST http://${KODISRV}/jsonrpc?Player.GetProperties | grep '"speed":1')" ]
			then	
				printf -- "[-] Device ${BTDEVICE} disconnected, Connection attempt\n"
				echo "connect ${BTDEVICE}" |  bluetoothctl 2>&1 
				sleep 1
			else
				printf -- "[-] Kodi@${KODISRV} is sleeping, me too\n"
				sleep 3
			fi			
		else
			printf -- "[-] Device ${BTDEVICE} connected, waiting 15 sec before next check\n"
			sleep 15
		fi
	fi
done

