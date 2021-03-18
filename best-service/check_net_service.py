#!/usr/bin/env python3
"""
  This script checks best tcp connect time between host:port
  list passed in parameters.
"""

import os
import sys
import socket
from time import time


# -------------------------------------------------------------------------
# Tools for verbose display
# -------------------------------------------------------------------------


class DisplayTools:
    def __init__(self, verbose=False):
        self.__verbose = verbose

    def action(self, msg):
        "Display message with [*] prefix in verbose mode"
        if self.__verbose:
            print("[*] {0}".format(msg))

    def info(self, msg):
        "Display message with [+] prefix in verbose mode"
        if self.__verbose:
            print("[+] {0}".format(msg))

    def error(self, msg):
        "Display message with [-] prefix in verbose mode"
        if self.__verbose:
            print("[-] {0}".format(msg))

    def gotit(self, msg):
        "Display message with [>] prefix in verbose mode"
        if self.__verbose:
            print(" >  {0}".format(msg))


class NetTools:
    """ NetTools"""

    _NO_SERVICE_FOUND = 404
    _SOME_ERROR = 206
    _OK = 0

    def __init__(self, verbose=False):
        self.display = DisplayTools(verbose)

    # -------------------------------------------------------------------------
    # Check Service
    # -------------------------------------------------------------------------

    def check_best_tcp_service(
        self,
        service_list,
        threshold=5,
        algo="fastest",
        last_used_first=False,
        data_store="~/.check_services",
        store=False,
    ):
        """ Check best service"""

        _STORE = os.path.expanduser(data_store)

        if last_used_first:
            self.display.action("Get last used service from {}".format(_STORE))
            # Use last use service first
            try:
                with open(_STORE, "r") as get_last_used:
                    service_list.insert(0, get_last_used.readline().strip())
            except FileNotFoundError:
                self.display.error("Store file not found {}".format(_STORE))

        best_time = threshold
        best_service = None
        best_status = NetTools._OK

        self.display.action(
            "Search {} service with {} threshold\n".format(algo, threshold)
        )

        socket.setdefaulttimeout(threshold)

        for cur_service in service_list:

            cur_service = cur_service.strip()
            try:
                host, port = cur_service.split(":")
            except ValueError:
                self.display.error("Bad parameter ({0})".format(cur_service))
                best_status = NetTools._SOME_ERROR
                continue

            self.display.action("host={0} port={1}".format(host, port))
            # No more parameter check,let socket.connect check and
            # catch error in exception

            try:
                time1 = time()
                with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as a_socket:
                    try:
                        a_socket.connect((host, int(port)))
                        time2 = time()
                    except (TypeError, ValueError):
                        self.display.error("Bad parameter")
                        best_status = NetTools._SOME_ERROR
                        continue
                    except socket.timeout:
                        self.display.error("Connect timeout error")
                        best_status = NetTools._SOME_ERROR
                        continue
                    except socket.gaierror:
                        self.display.error("Connect error")
                        best_status = NetTools._SOME_ERROR
                        continue

                if algo == "first_up":
                    return NetTools._OK, cur_service

                connect_time = time2 - time1

                if connect_time < best_time:
                    best_time = connect_time
                    best_service = cur_service
                    self.display.gotit("{0} {1}".format(cur_service, connect_time))
                else:
                    self.display.info(" {0} {1}".format(cur_service, connect_time))

            except OSError:
                best_status = NetTools._SOME_ERROR
                self.display.error("Socket error")

        if store and best_service is not None:
            # Update last used service
            try:
                with open(_STORE, "w") as get_last_used:
                    get_last_used.write(str(best_service))
                self.display.action(
                    "Store last used service {} in {}".format(best_service, _STORE)
                )
            except OSError:
                self.display.error(
                    "Error storing last used service in {}".format(_STORE)
                )

        if best_service is None:
            return NetTools._NO_SERVICE_FOUND, ""

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

    tools = NetTools(verbose=_VERBOSE)

    # Run check
    (status, service) = tools.check_best_tcp_service(
        service_list=args.service,
        threshold=args.threshold,
        algo=args.algo,
        last_used_first=args.last_used_first,
        data_store=_STORE,
        store=args.store,
    )

    print(service)
    sys.exit(status)
