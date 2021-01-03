#!/usr/bin/env python3
"""
  This script checks best tcp connect time between host:port
  list passed in parameters.
"""

import os
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
        print("[*] {0}".format(msg))


def info(msg):
    "Display message with [+] prefix in verbose mode"
    if _VERBOSE:
        print("[+] {0}".format(msg))


def error(msg):
    "Display message with [-] prefix in verbose mode"
    if _VERBOSE:
        print("[-] {0}".format(msg))


def gotit(msg):
    "Display message with [>] prefix in verbose mode"
    if _VERBOSE:
        print(" >  {0}".format(msg))


# -------------------------------------------------------------------------
# Check Service
# -------------------------------------------------------------------------


def check_best_tcp_service(service_list, threshold=5, algo="fastest"):
    """ Check best service"""

    best_time = threshold
    best_service = None
    best_status = _OK

    action("Search {} service with {} threshold\n".format(algo, threshold))

    socket.setdefaulttimeout(threshold)

    for cur_service in service_list:

        cur_service = cur_service.strip()
        try:
            host, port = cur_service.split(":")
        except ValueError:
            error("Bad parameter ({0})".format(cur_service))
            best_status = _SOME_ERROR
            continue

        action("host={0} port={1}".format(host, port))
        # No more parameter check,let socket.connect check and
        # catch error in exception

        try:
            time1 = time()
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as a_socket:
                try:
                    a_socket.connect((host, int(port)))
                    time2 = time()
                except (TypeError, ValueError):
                    error("Bad parameter")
                    best_status = _SOME_ERROR
                    continue
                except socket.timeout:
                    error("Connect timeout error")
                    best_status = _SOME_ERROR
                    continue
                except socket.gaierror:
                    error("Connect error")
                    best_status = _SOME_ERROR
                    continue

            if algo == "first_up":
                return _OK, cur_service

            connect_time = time2 - time1

            if connect_time < best_time:
                best_time = connect_time
                best_service = cur_service
                gotit("{0} {1}".format(cur_service, connect_time))
            else:
                info(" {0} {1}".format(cur_service, connect_time))

        except OSError:
            best_status = _SOME_ERROR
            error("Socket error")

    if best_service is None:
        return _NO_SERVICE_FOUND, ""

    return best_status, best_service


# -------------------------------------------------------------------------
# Main process
# -------------------------------------------------------------------------

if __name__ == "__main__":

    # Process passed arguments.
    import argparse

    parser = argparse.ArgumentParser(description="Net Service Checker")

    parser.add_argument("--verbose", "-v", action="store_true", help="verbose.")

    parser.add_argument(
        "--threshold",
        "-t",
        default=1000,
        type=float,
        help="Threshold for acceptable service (float).",
    )

    parser.add_argument(
        "--no-store",
        action="store_false",
        dest="store",
        help="Do not store lastused service",
    )

    parser.add_argument(
        "--last-used-store",
        dest="last_used_store",
        default="~/.check_services",
        help="File pasth used to store lastused service (default: ~/.check_services)",
    )

    parser.add_argument(
        "--last-used-first",
        action="store_true",
        dest="last_used_first",
        help="Use last first",
    )

    parser.add_argument(
        "--algo",
        "-a",
        default="fastest",
        choices=["fastest", "first_up"],
        help="Check algorithm (default: fastest)",
    )

    parser.add_argument(
        "service", nargs="+", help="list of services to check in forme host:port"
    )

    args = parser.parse_args()

    _VERBOSE = args.verbose
    _STORE = os.path.expanduser(args.last_used_store)

    if args.last_used_first:
        action("Get last used service from {}".format(_STORE))
        # Use last use service first
        try:
            with open(_STORE, "r") as get_last_used:
                args.service.insert(0, get_last_used.readline().strip())
        except FileNotFoundError:
            error("store fil not found {}".format(_STORE))

    # Run check
    (status, service) = check_best_tcp_service(
        service_list=args.service, threshold=args.threshold, algo=args.algo
    )

    if args.store and service is not None:
        # Update last used service
        try:
            with open(_STORE, "w") as get_last_used:
                get_last_used.write(str(service))
            action("Store last used service {} in {}".format(service, _STORE))
        except OSError:
            error("Error storing last used service in {}".format(_STORE))

    print(service)
    sys.exit(status)
