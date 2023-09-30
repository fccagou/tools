

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


## amixer

Has the user running sound server pipewire or pulseaudio, run amixer to change
the volume 

* Set volume to 80%

    amixer sset Master 80%

* Increase volume by 5%

    amixer sset Master 5%+

* Decrease volume by 5%

    amixer sset Master 5%-

# pipewire

## cli

All cli commands start with `pw-`






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



