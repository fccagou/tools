#!/usr/bin/env python3
#
# Author: fccagou <me@fccagou.fr>
# Status: sandbox
#
#
from os import getuid
from pynput import keyboard
from subprocess import Popen
# PI keyboard
# Play Music
# alphanumeric key None pressed
# <269025153> released
# Search
# alphanumeric key None pressed
# <269025051> released
# Home
# alphanumeric key None pressed
# <269025117> released


# TODO: get the standard.
env={
        "XDG_RUNTIME_DIR": "/run/user/{0}".format(getuid())
}

# Just for documentation
cmds_to_implement = {
  keyboard.Key.media_play_pause: "echo not defined",
  keyboard.Key.media_next: "echo not defined",
  keyboard.Key.media_previous: "echo not defined",
  keyboard.Key.right: "echo not defined",
  keyboard.Key.left: "echo not defined",
  keyboard.Key.up: "echo not defined",
  keyboard.Key.down: "echo not defined",
  keyboard.Key.f1: "echo not defined",
  keyboard.Key.f2: "echo not defined",
}

cmds_amixer ={
  keyboard.Key.media_volume_up: "amixer sset Master 5%+",
  keyboard.Key.media_volume_down: "amixer sset Master 5%-",
  keyboard.Key.media_volume_mute: "amixer sset Master toggle",
}

cmds_wpctl = {
  keyboard.Key.media_volume_up: "/usr/bin/wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+",
  keyboard.Key.media_volume_down: "/usr/bin/wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%-",
  keyboard.Key.media_volume_mute: "/usr/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
}


kb = keyboard.Controller()
# TODO: make automatic and parameter choice
cmds = cmds_wpctl

def on_press(key):
    try:
        print('alphanumeric key {0} pressed'.format(
            key.char))
    except AttributeError:
        print('special key {0} pressed'.format(
            key))

def on_release(key):
    if key == keyboard.Key.media_play_pause:
        kb.press(keyboard.Key.space)
        kb.release(keyboard.Key.space)
    elif key in cmds:
        print("Exec: {0}".format(cmds[key]))
        process = Popen(cmds[key].split(" "), env=env)
        process.wait()
    else:
        print(f"no callback for: {key}")

# Collect events until released
with keyboard.Listener(
        # on_press=on_press,
        on_release=on_release) as listener:
    listener.join()

# ...or, in a non-blocking fashion:
# listener = keyboard.Listener(
#     on_press=on_press,
#     on_release=on_release)
# listener.start()

