
# kodi check bluetooth

## Why 

Because bluetooth connection is not managed correctly in [OpenElec](http://openelec.tv/) and [LibreElec](https://libreelec.tv/),
I have created this workaround.

## How
 
The shell [kodi-check-bluetooth.sh](kodi-check-bluetooth.sh) reconnect the defined bluetooth device if
not connected.

Variables:

- BTDEVICE: must contains the mac addr of the BT device
- KODISRV: must contains _kodiserver:port_ 

In my case, the bluetooth connection powers on the device. Because the
script checks every 15 sec, that means the bt device is never in standbye mode.
To avoid this, the script checks if music is played using Kodi's jsonrpc API.
So, even my BT device is in standby mode, playing music with kodi actives it.
**\o/**


The [kodi-check-bluetooth.service](kodi-check-bluetooth.service) is coded for libreelec. It can be adapted
for OpenElec (or ...).

## Future

Comments are welcomed !!


