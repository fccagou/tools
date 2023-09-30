#!/usr/bin/env python3
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

env={
        "XDG_RUNTIME_DIR": "/run/user/{0}".format(getuid())
}

cmds={
  keyboard.Key.media_volume_up: "amixer sset Master 5%+",
  keyboard.Key.media_volume_down: "amixer sset Master 5%-",
  keyboard.Key.media_volume_mute: "amixer sset Master toggle",
  keyboard.Key.media_play_pause: "echo not defined",
  keyboard.Key.media_next: "echo not defined",
  keyboard.Key.media_previous: "echo not defined",
  keyboard.Key.right: "echo not defined",
  keyboard.Key.left: "echo not defined",
  keyboard.Key.up: "echo not defined",
  keyboard.Key.down: "echo not defined",
}

kb = keyboard.Controller()

def on_press(key):
    try:
        print('alphanumeric key {0} pressed'.format(
            key.char))
    except AttributeError:
        print('special key {0} pressed'.format(
            key))

def on_release(key):
    print('{0} released'.format(
        key))
    if key == keyboard.Key.esc:
        # Stop listener
        return False

    if key == keyboard.Key.media_play_pause:
        kb.press(keyboard.Key.space)
        kb.release(keyboard.Key.space)
    elif key in cmds:
        print("Exec: {0}".format(cmds[key]))
        process = Popen(cmds[key].split(" "), env=env)
        process.wait()

# Collect events until released
with keyboard.Listener(
        on_press=on_press,
        on_release=on_release) as listener:
    listener.join()

# ...or, in a non-blocking fashion:
# listener = keyboard.Listener(
#     on_press=on_press,
#     on_release=on_release)
# listener.start()

