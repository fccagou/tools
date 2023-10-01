---
title: Manage sound under linux terminal
author: François Chenais
---

# Command line

## Tips

If some programs does'nt work in command line, try setting `XDG_RUNTIME_DIR`
before. For exemple, reduce sound by 5%.

    XDG_RUNTIME_DIR=/run/user/$(id -u)  amixer sset Master 5%-

Has root for automation

     su - userX -c 'XDG_RUNTIME_DIR=/run/user/$(id -u)  amixer sset Master 5%-'

## Check if the sound server running

Find the process

    ps auxwf | grep -E 'pipewire|pulse' | grep -v grep
    # pi         844  0.2  0.3  51108 13072 ?        S<sl 17:57   0:01  \_ /usr/bin/pipewire
    # pi         846  0.5  0.3  39948 13120 ?        S<Lsl 17:57   0:04  \_ /usr/bin/pipewire-pulse


Get the XDG_RUNTIME_DIR value 

    cat /proc/844/environ | tr '\0' '\n' | grep XDG_RUNTIME_DIR
or

    sed 's/.*\(XDG_RUNTIME_DIR=[^\x0]*\).*/\1\n/'  /proc/844/environ

## wpctl

- get informations

    wpctl status


- Set volume to 80%

    wpctl

- Increase volume by 5%

    /usr/bin/wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+

- Decrease volume by 5%

    /usr/bin/wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%-

- Mute

     /usr/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

- Mute microphone

     /usr/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

## amixer

Has the user running sound server pipewire or pulseaudio, run amixer to change
the volume 

- Set volume to 80%

    amixer sset Master 80%

- Increase volume by 5%

    amixer sset Master 5%+

- Decrease volume by 5%

    amixer sset Master 5%-

- Mute

    amixer sset Master toggle


# pipewire


## Make a virtual device with all sinks/output

First, create virtual sink called all_sinks

    cat $HOME/.config/pipewire/pipewire.conf.d/50-create-sink-all-output.conf

    context.modules = [
    {   name = libpipewire-module-combine-stream
        args = {
            combine.mode = sink
            node.name = "all_sinks"
            node.description = "Tout a porté de main"
            combine.latency-compensate = false   # if true, match latencies by adding delays
            combine.props = {
                audio.position = [ FL FR ]
            }
            stream.props = {
            }
            stream.rules = [
                {
                    matches = [ { media.class = "Audio/Sink" } ]
                    actions = { create-stream = { } }
                }
            ]
        }
    }
    ]

Set it as default sink

    cat $HOME/.config/pipewire/pipewire.conf.d/99-set-defaults.conf

    context.properties = {
      default.configured.audio.sink = { "name": "all_sinks" }
    }



# Lirc

Need xmacro

     cat ~/.lircrc

     begin
             prog = irexec
             button = KEY_VOLUMEUP
             repeat = 1
             delay = 2
             config = echo KeyStrPress XF86AudioRaiseVolume KeyStrRelease XF86AudioRaiseVolume | xmacroplay $DISPLAY
     end
     begin
             prog = irexec
             button = KEY_VOLUMEDOWN
             repeat = 1
             delay = 2
             config = echo KeyStrPress XF86AudioLowerVolume KeyStrRelease XF86AudioLowerVolume | xmacroplay $DISPLAY
     end
     begin
             prog = irexec
             button = KEY_MUTE
             config = echo KeyStrPress XF86AudioMute KeyStrRelease XF86AudioMute | xmacroplay $DISPLAY
     end


# Bluetooh devices


On debian, the `libspa-0.2-bluetooth` package must be installed to get sound
working using BT devices. (TODO: check how the magical works)

    dpkg -L libspa-0.2-bluetooth
    /usr/lib/arm-linux-gnueabihf/spa-0.2/bluez5
    /usr/lib/arm-linux-gnueabihf/spa-0.2/bluez5/libspa-bluez5.so
    /usr/lib/arm-linux-gnueabihf/spa-0.2/bluez5/libspa-codec-bluez5-aptx.so
    /usr/lib/arm-linux-gnueabihf/spa-0.2/bluez5/libspa-codec-bluez5-faststream.so
    /usr/lib/arm-linux-gnueabihf/spa-0.2/bluez5/libspa-codec-bluez5-lc3.so
    /usr/lib/arm-linux-gnueabihf/spa-0.2/bluez5/libspa-codec-bluez5-ldac.so
    /usr/lib/arm-linux-gnueabihf/spa-0.2/bluez5/libspa-codec-bluez5-opus.so
    /usr/lib/arm-linux-gnueabihf/spa-0.2/bluez5/libspa-codec-bluez5-sbc.so
    /usr/share/doc/libspa-0.2-bluetooth/changelog.Debian.gz
    /usr/share/doc/libspa-0.2-bluetooth/copyright
    /usr/share/spa-0.2/bluez5/bluez-hardware.conf


# Troubles

## Yamaha YAS 306

This
[device](https://fr.yamaha.com/fr/products/audio_visual/sound_bar/yas-306/features.html)
has a strange behaviour with bluetooth connection. It connects then disconnect
and bluetoothd (-does nothing to retry-) retry connection if the option
`Experimental = true` is present in bluetoth's `main.conf`file.
_(Manually `bluetoothctl connect MAC_addr` works fine too)_

But the device is default set to muted.

This is boring when you want to configure a pipewire virtual sink with many
device as described abow because :
  - the virtual sink is muted
  - if firefox playing sound, it stops
 
Just found an old python code [bluetooth-autoconnect](https://github.com/jrouleau/bluetooth-autoconnect.git)
trying to deal with bad connection but it fails in modern systems. Seems looking for DBus messages not presents.

TODO: read the code :P
