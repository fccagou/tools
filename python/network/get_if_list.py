#!/usr/bin/python

# From scapy/arch/linux.py
#


def plain_str(x):
    # type: (Any) -> str
    """Convert basic byte objects to str"""
    if isinstance(x, bytes):
        return x.decode(errors="backslashreplace")
    return str(x)


def _get_if_list():
    """
    Function to read the interfaces from /proc/net/dev
    """
    try:
        f = open("/proc/net/dev", "rb")
    except IOError:
        try:
            f.close()
        except Exception:
            pass
        log_loading.critical("Can't open /proc/net/dev !")
        return []
    lst = []
    f.readline()
    f.readline()
    for line in f:
        line = plain_str(line)
        lst.append(line.split(":")[0].strip())
    f.close()
    return lst


for i in _get_if_list():
    print(i)


txt = "My name is Ståle"

print(txt.encode(encoding="ascii", errors="backslashreplace"))
print(txt.encode(encoding="ascii", errors="ignore"))
print(txt.encode(encoding="ascii", errors="namereplace"))
print(txt.encode(encoding="ascii", errors="replace"))
print(txt.encode(encoding="ascii", errors="xmlcharrefreplace"))

import struct

print(struct.pack("16s16x", "lo".encode("utf8")))
