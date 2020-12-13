#!/usr/bin/env python3
"""
  This script checks best tcp connect time between host:port
  list passed in parameters.
"""

import sys
import socket
from time import time

_NO_SERVICE_FOUND = 404
_SOME_ERROR = 206
_OK = 0

# -------------------------------------------------------------------------
# Tools for verbose display
# -------------------------------------------------------------------------

_VERBOSE = False

def action(msg):
    "Display message with [*] prefix in verbose mode"
    if _VERBOSE:
        print ("[*] {0}".format(msg))

def info(msg):
    "Display message with [+] prefix in verbose mode"
    if _VERBOSE:
        print ("[+] {0}".format(msg))

def error(msg):
    "Display message with [-] prefix in verbose mode"
    if _VERBOSE:
        print ("[-] {0}".format(msg))


def gotit(msg):
    "Display message with [>] prefix in verbose mode"
    if _VERBOSE:
        print ("[>] {0}".format(msg))

# -------------------------------------------------------------------------
# Doc
# -------------------------------------------------------------------------

def usage():
    "Show program's usage"

    print ("""
Usage {0}: [-h|--help] | [-v|--verbose] [-t|--threshold] host1:port1 [host2:port2]..[hostn:portn]

       -h|--help         :  this help
       -v|--verbose      :  verbose mode (before -t option)
       -t|--threshold    :  acceptable connect time threshold
       host:port         :  tcp host:port to check

RETURNS:

      host:port           : the quicker responder.

""".format(sys.argv[0]))


# -------------------------------------------------------------------------
# Check Service
# -------------------------------------------------------------------------

def check_best_tcp_service(service_list, threshold=5):
    """ Check best service"""

    best_time = threshold
    best_service = None
    best_status = _OK

    action ("Search best service with {0} threshold\n".format(threshold))

    socket.setdefaulttimeout( threshold )

    for cur_service in service_list:

        cur_service = cur_service.strip()
        try:
            host,port = cur_service.split(':')
        except ValueError:
            error("Bad parameter ({0})".format(cur_service))
            best_status = _SOME_ERROR
            continue

        action("host={0} port={1}".format(host,port))
        # No more parameter check,let socket.connect check and
        # catch error in exception

        try:
            time1 = time()
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as a_socket:
                try:
                    a_socket.connect((host, int(port)))
                    time2 = time()
                except (TypeError, ValueError):
                    error('Bad parameter')
                    best_status = _SOME_ERROR
                    continue
                except socket.timeout:
                    error('Connect timeout error')
                    best_status = _SOME_ERROR
                    continue
                except socket.gaierror:
                    error('Connect error')
                    best_status = _SOME_ERROR
                    continue

            connect_time = time2 - time1

            if connect_time < best_time:
                best_time = connect_time
                best_service = cur_service
                gotit ( "{0} {1}".format(cur_service, connect_time))
            else:
                info ( " {0} {1}".format(cur_service, connect_time))

        except OSError:
            best_status = _SOME_ERROR
            error('Socket error')

    if best_service is None:
        return _NO_SERVICE_FOUND,''

    return best_status,best_service


# -------------------------------------------------------------------------
# Main process
# -------------------------------------------------------------------------

if __name__ == "__main__":

    _THRESHOLD=1000
    # I should have used argparse ... but not needed now K.I.S.S.

    if len(sys.argv) == 1:
        usage ()
        sys.exit(1)

    _FIRST_ARG = 1
    if sys.argv[_FIRST_ARG] == '-h' or sys.argv[_FIRST_ARG] == '--help':
        usage ()
        sys.exit(0)

    if sys.argv[_FIRST_ARG] == '-v' or sys.argv[_FIRST_ARG] == '--verbose':
        _VERBOSE = True
        _FIRST_ARG = 2

    if sys.argv[_FIRST_ARG] == '-t' or sys.argv[_FIRST_ARG] == '--threshold':
        _FIRST_ARG +=1
        try:
            _THRESHOLD = sys.argv[_FIRST_ARG]
            _FIRST_ARG += 1
        except IndexError:
            usage ()
            sys.exit(1)

    (status, service) = check_best_tcp_service (
                service_list = sys.argv[_FIRST_ARG:],
                threshold = float(_THRESHOLD)
            )

    print(service)
    sys.exit(status)
