---
title: Manage bluetooth under linux terminal
author: François Chenais
---

# Presentation

Some tips about bluetooth


# Installation

On linux, hardware access is made by hci interface.
Then install `bluez` to get `bluetoothd` daemon interact with hardware and
`bluetoothctl` tool for user to configure bluetooth through bluetoothd.


To allow multiple connected devices, ensure `MultiProfile = multiple` in
`/etc/bluetooth/main.conf`. If not, change the value and restart bluetooth
service (`systemctl restart bluetooth`)

# Bluetoothctl


Get harware devices known has Controllers

    bluetoothctl -- list
    Controller B8:27:EB:57:B4:C9 pi4chu [default]

Get known devices

    bluetoothctl -- devices
    Device 5C:F8:21:AC:80:F2 YAS-306 D971BA Bluetooth
    Device 78:5E:A2:96:55:C7 MIDDLETON

Get connected devices

    bluetoothctl -- devices Connected
    Device 5C:F8:21:AC:80:F2 YAS-306 D971BA Bluetooth

To change device, juste disconnect current and the system automaticaly connects
the next one (TODO: check this point)

    bluetoothctl -- disconnect 5C:F8:21:AC:80:F2
    Attempting to disconnect from 5C:F8:21:AC:80:F2
    [DEL] Player /org/bluez/hci0/dev_5C_F8_21_AC_80_F2/player0 [default]
    [DEL] Transport /org/bluez/hci0/dev_5C_F8_21_AC_80_F2/sep1/fd8 
    [DEL] Endpoint /org/bluez/hci0/dev_5C_F8_21_AC_80_F2/sep1 
    [DEL] Endpoint /org/bluez/hci0/dev_5C_F8_21_AC_80_F2/sep2 
    [DEL] Endpoint /org/bluez/hci0/dev_5C_F8_21_AC_80_F2/sep3 
    [DEL] Endpoint /org/bluez/hci0/dev_5C_F8_21_AC_80_F2/sep4 
    [DEL] Endpoint /org/bluez/hci0/dev_5C_F8_21_AC_80_F2/sep5 
    [DEL] Endpoint /org/bluez/hci0/dev_5C_F8_21_AC_80_F2/sep6 
    [DEL] Endpoint /org/bluez/hci0/dev_5C_F8_21_AC_80_F2/sep7 
    [CHG] Device 5C:F8:21:AC:80:F2 ServicesResolved: no
    Successful disconnected

    bluetoothctl devices Connected
    Device 78:5E:A2:96:55:C7 MIDDLETON




For more helps, RTFM

    bluetoothctl -- help

# btmgmt

    btmgmt help


# External refecences

- [Archlinux Documentation](https://wiki.archlinux.org/title/bluetoothctl)
- [BT LE](https://elinux.org/images/3/32/Doing_Bluetooth_Low_Energy_on_Linux.pdf)
