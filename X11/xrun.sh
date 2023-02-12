#!/bin/bash
#

xcmd="${1:-/usr/bin/xeyes}"


xorgpid="$(/usr/bin/pidof Xorg)"


[ -z "$xorgpid" ] && {
    printf -- "ERROR: Xorg not running\n"
    exit 1
}

XAUTHORITY="$(cat /proc/"$xorgpid"/cmdline | tr '\000' ' ' | sed -e 's/.*-auth \([^ ]\+\) .*$/\1/')"


[ -z "$XAUTHORITY" ] && {
    printf -- "ERROR: no Xauthority file fouond in cmdline\n"
    exit 1
}

DISPLAY="$(cat /proc/"$xorgpid"/cmdline | tr '\000' ' ' | sed -e 's/.*\(:[0-9]\+\)[ ]*.*$/\1/')"

[ -z "$DISPLAY" ] && DISPLAY=:0

export DISPLAY
export XAUTHORITY


"$xcmd"
