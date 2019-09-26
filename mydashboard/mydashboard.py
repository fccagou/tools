#!/usr/bin/env python
#
"""
Local Dashboard for easy configuration.

The aim is to give access for some tools from webbrowser

- Read commande list from config files
  
  - system config
  - user config

- Access from web page
- application runs with user right
- Allow use to add own application
- Can run graphical applications



"""

from __future__ import print_function

import os
import ssl
import sys
import json
import time
import signal
import mimetypes
import subprocess
import wsgiref.simple_server as server

from threading import Thread

# -----------------------------------------------------------------
#  python wrapper
# -----------------------------------------------------------------
try:
    # For Python 3.0 and later
    from urllib.request import urlopen
    MYURLOPEN = lambda url, timeout, context: urlopen(url=url, timeout=timeout, context=context)
except ImportError:
    # Fall back to Python 2's urllib2
    from urllib2 import urlopen
    MYURLOPEN = lambda url, timeout, context: urlopen(url=url, timeout=timeout)

def wsgi_to_bytes(str2convert):
    """
    Because of https://www.python.org/dev/peps/pep-3333/#unicode-issues
    """
    return str2convert.encode('iso-8859-1')
    
    


# -----------------------------------------------------------------
# Global Variables.
# -----------------------------------------------------------------
# Default web server listening port
LISTENING_PORT = 8080

# For debuging
verbose = False

# Document Root for static web pages.
document_root = '/etc/mydashboard/html'

# ssl context for unverified site.
ssl_default_ctx = None

# -----------------------------------------------------------------
# Informational functions.
# -----------------------------------------------------------------
def log(msg):
    global verbose
    if verbose:
        print("[+] - ", msg)
    else:
        pass

def info(msg):
    global verbose
    if verbose:
        print("[i] - ", msg)
    else:
        pass

def warning(msg):
    global verbose
    if verbose:
        print("[!] - ", msg)
    else:
        pass

def error(msg):
    global verbose
    if verbose:
        print("[-] - ", msg)
    else:
        pass



# -----------------------------------------------------------------
# HTTP: default page showing all notifiers status.
# -----------------------------------------------------------------
def static_page(start_response, filename):
    global ssl_default_ctx
    global document_root

    status = "200 OK"

    try:
        real_file_path = os.path.join(document_root,filename)
        output = open(real_file_path, 'rb').read()
        ctype = mimetypes.guess_type(real_file_path)[0]
    except:
        status = "500 INTERNAL ERROR"
        import traceback
        warning("INTERNAL ERROR: %s " %  sys.exc_info()[0])
        print('-'*60)
        traceback.print_exc(file=sys.stdout)
        print('-'*60)
        output = "The code seems to have an internal error :("
        ctype = 'text/plain; charset=UTF-8'

    response_headers = [('Content-type', ctype),
                        ('Content-Length', str(len(output)))]
    start_response(status, response_headers)
    return [output]

def jsonapi(start_response, data):
    global ssl_default_ctx

    status = "200 OK"

    try:
        import json
        output = json.dumps(data)
        ctype='application/json; charset=UTF-8'        
    except:
        status = "500 INTERNAL ERROR"
        import traceback
        warning("INTERNAL ERROR: %s " %  sys.exc_info()[0])
        print('-'*60)
        traceback.print_exc(file=sys.stdout)
        print('-'*60)
        output = "The code seems to have an internal error :("
        ctype = 'text/plain; charset=UTF-8'

    response_headers = [('Content-type', ctype),
                        ('Content-Length', str(len(output)))]
    start_response(status, response_headers)
    return [wsgi_to_bytes(output)]

def notfound(start_response, url):

    status = '404 NOT FOUND'
    output = "%s not found\n" % url
    response_headers = [('Content-type', 'text/plain'),
                        ('Content-Length', str(len(output)))]
    start_response(status, response_headers)
    return [wsgi_to_bytes(output)]


def run_cmd(cmd_set):
    pid = os.fork()
    if pid == 0:
        subprocess.run(("/usr/bin/xterm -e %s" % cmd_set[0] ), shell=True)
        # Decouple from parent environment
        os.setsid()
        # TODO os.umask()
        # Redirect the standard I/O file descriptors to /dev/null
        if hasattr(os, "devnull"):
            REDIRECT_TO = os.devnull
        else:
            REDIRECT_TO = "/dev/null"

        fd = os.open(REDIRECT_TO, os.O_RDWR)
        os.dup2(fd, 0)  # standard input (0)
        os.dup2(fd, 1)  # standard output (1)
        os.dup2(fd, 2)  # standard error (2)
        os._exit(0)


# -----------------------------------------------------------------
# HTTP: WEB APP
# -----------------------------------------------------------------
def application(environ, start_response):

    if environ['PATH_INFO'] in ['/bootstrap.min.css', '/jquery.min.js', '/bootstrap.bundle.js']:
        return static_page(start_response, environ['PATH_INFO'][1:])


    if environ['PATH_INFO'] == "/firefox":
        run_cmd(["/usr/bin/firefox", "http://localhost:8080/"])

    elif environ['PATH_INFO'] == "/top":
        run_cmd(["/usr/bin/top"])

    elif environ['PATH_INFO'] == "/ts/list":
        TSLIST={}

        for centre in ('Z','U','T','X','Y'):
            TSLIST[centre]={}
            for color in ('rouge','jaune','vert','blanc'):
               TSLIST[centre][color]=[]
               TSLIST[centre][color].append("ts %s %s" % (centre,color))
               TSLIST[centre][color].append("ts %s %s" % (color,centre))

        return jsonapi(start_response,TSLIST)

    elif environ['PATH_INFO'][0:4] == "/ts/":
        (centre,couleur) = environ['PATH_INFO'][4:].split('/')
        if couleur == 'bleu':
            run_cmd(["'/usr/bin/ssh pi@pi02'" ])
        else:
            run_cmd(["'/usr/bin/echo %s %s >/tmp/toto'" %(centre,couleur) ])



    else:
        # TODO: passer un message d'erreur
        True

   
    return static_page(start_response, 'template.html')


# -----------------------------------------------------------------
# MAIN PROGRAM.
# -----------------------------------------------------------------
def EndException(BaseException):
    def __init__(self, value):
        self.value = value
    def __str__(self):
        return repr(self.value)

def end_process(signum, frame):
    raise EndException('Signal catch')



def main(args):

    global verbose
    global document_root
    global ssl_default_ctx

    verbose = args.verbose
    debug = args.debug



    # Catch signal to quit cleanly.
    signal.signal(signal.SIGTERM, end_process)
    signal.signal(signal.SIGQUIT, end_process)

    if debug:
        log("args list: %s " %  args)

    # Get configuration from file.
    if args.conf is not None:
        log('Using config file %s' % args.conf)
        conf = json.loads(open(args.conf, 'r').read())

        if 'documentroot' in conf:
            document_root = conf['documentroot']

        if 'ssl_allow_unverified' in conf and conf['ssl_allow_unverified'] == "True":
            ssl_default_ctx = ssl._create_unverified_context()


    if args.documentroot:
        document_root = args.documentroot

    document_root = os.path.abspath(document_root)


    if debug:
        log("document_root: %s" % document_root)

    stop_thread = False
    try:
        if args.server:
            port = args.port
            httpd = server.make_server('', port, application)
            log("Serving HTTP on port %i..." % port)
            # Respond to requests until process is killed
            httpd.serve_forever()
        else:
            print("[+] Nothing to poll or to serve... I leave ...")
    except KeyboardInterrupt:
        log('End asked by user...bye bye !')
    except EndException as ee:
        log(ee.value)
    except:
        print("Unexpected error:", sys.exc_info()[0])
    finally:
        # Ending all process and switch notifiers off before leaving.
        stop_thread = True

        log("Waiting end of process")
        time.sleep(2)

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

    parser.add_argument('--conf', '-c',
                        help='Configuration file.')
    parser.add_argument('--notifiers', '-n',
                        help='Notifiers list in Blink1Notifier,SerialLedNotifier')
    parser.add_argument('--server', '-s', action='store_true',
                        help="Run http listening server (default=false)")
    parser.add_argument('--port', '-p', default=LISTENING_PORT, type=int,
                        help='Listening port for status push .')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Verbose.')
    parser.add_argument('--debug', '-d', action='store_true',
                        help='Debug mode.')
    parser.add_argument('--fg', action='store_true',
                        help='Forground mode. Disable daemon mode.')
    parser.add_argument('--nopid', action='store_true',
                        help='Disable writing pid file (see --pidfile)')
    parser.add_argument('--pidfile', default='/var/run/pyap.pid',
                        help='Set the pid file.')
    parser.add_argument('--documentroot', '-D', default=None,
                        help='Document root for static web pages.')
    parser.add_argument('urls', nargs='*',
                        help='url for http state poller')

    args = parser.parse_args()

    if not args.fg:
        # do the UNIX double-fork magic, see Stevens' "Advanced
        # Programming in the UNIX Environment" for details (ISBN 0201563177)
        if args.debug or args.verbose:
            log('Running daemon mode.')

        if os.fork() > 0:
            sys.exit(0)

        # Decouple from parent environment
        os.chdir('/')
        os.setsid()
        # TODO os.umask()
        # Redirect the standard I/O file descriptors to /dev/null
        if hasattr(os, "devnull"):
            REDIRECT_TO = os.devnull
        else:
            REDIRECT_TO = "/dev/null"

        fd = os.open(REDIRECT_TO, os.O_RDWR)
        os.dup2(fd, 0)  # standard input (0)
        os.dup2(fd, 1)  # standard output (1)
        os.dup2(fd, 2)  # standard error (2)

        # Double-fork magic must be single-fork for systemd
        # TODO: test under centos6 using init.
        # if os.fork() > 0:
        #     sys.exit(0)

    if not args.nopid:
        with open(args.pidfile, 'w') as f:
            f.write(str(os.getpid()))

    main(args)

    if not args.nopid:
        os.remove(args.pidfile)

    os._exit(os.EX_OK)
