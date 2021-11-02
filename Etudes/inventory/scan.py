#!/usr/bin/env python
# -*- encoding: utf-8 -*-

import logging
import socket
import sys

from ClusterShell.Task import task_self
task = task_self()


# -----------------------------------------------------------------
# Informational functions.
# -----------------------------------------------------------------

def log(msg):
    global config
    if config.verbose:
        print("[+] ", msg)
    else:
        pass

def info(msg):
    global config
    if config.verbose:
        print("[i] ", msg)
    else:
        pass

def warning(msg):
    global config
    if config.verbose:
        print("[!] ", msg)
    else:
        pass

def error(msg):
    global config
    if config.verbose:
        print("[-] ", msg)
    else:
        pass

def debug(msg):
    global config
    if config.debuging:
        logging.debug(msg)

# -----------------------------------------------------------------
# GLOBAL CONFIG
# -----------------------------------------------------------------

class MyConfig:
    def __init__(self):

        # For debuging
        self.verbose = False


config = MyConfig()


# -----------------------------------------------------------------
# DNS enum network
# -----------------------------------------------------------------
def dns_enum(network='127.0.0'):
    host_list={}
    for i in range(1,253):
        ip = '.'.join((network,str(i)))
        try:
            host_list[ip] = socket.gethostbyaddr(ip)[0]
        except:
            # unknown host
            host_list[ip] = 'unknown'

    return host_list

# -----------------------------------------------------------------
#  Main
# -----------------------------------------------------------------
def main(args):

    if not args.netlist:
        error("no network provides using --netlist parameter")
        sys.exit(1)

    host_list={}
    for n in args.netlist.split(','):
        log ("Scanning %s" %n)
        host_list.update(dns_enum(n))

    for k in host_list:
        if host_list[k] != 'unknown':
            print (host_list[k])





# -----------------------------------------------------------------
if __name__ == '__main__':
    # Process passed arguments.
    try:
        import argparse
        parser = argparse.ArgumentParser(
            description='Notify processor.',
            )
        USING_ARGPARSE = True
    except ImportError:
        import optparse
        parser = optparse.OptionParser(
            description='PYthon Alert Processor.')
        parser.parse_args_orig = parser.parse_args
        parser.parse_args = lambda: parser.parse_args_orig()[0]
        parser.add_argument = parser.add_option
        USING_ARGPARSE = False


    parser.add_argument('--netlist',
                        help='Network list (n1,n2,n3,...).')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='verbose.')

    args = parser.parse_args()

    config.verbose=args.verbose

    main(args)
