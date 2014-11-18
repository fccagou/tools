#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#
# Quick  Django virtualenv creator
#

import os,sys
import subprocess


try:
    django_venv=sys.argv[1]
    if django_venv == '-h' or django_venv == '--help':
        print """\n\nUsage: %s [-h|--help] [path_to_django_env]\n\n""" % sys.argv[0]
        sys.exit(0)
except IndexError:
    django_venv='django-venv'




def git(*args):
    print subprocess.check_output(['git'] + list(args),
            stderr=subprocess.STDOUT)

def pip(*args):
    return subprocess.check_output([os.path.join(django_venv, 'bin','pip')] +
            list(args), stderr=subprocess.STDOUT)


if sys.version_info < (2,7):
    django_version='=1.6.8'
else:
    django_version=''

try:
    import virtualenv
except:
    print "No virtualenv on this host. Getting it from github\n"
    if os.path.isdir('virtualenv'):
        git('--work-tree=virtualenv', 'pull')
    else:
        git('clone', 'https://github.com/pypa/virtualenv.git')
    sys.path.insert('virtualenv')
    import virtualenv


if os.path.isdir(django_venv):
    print "%s exists yet !\n" % django_venv
else:
    print "Creating %s\n" % django_venv
    virtualenv.create_environment(django_venv)


activate_this = os.path.join( django_venv,'bin', 'activate_this.py')
execfile(activate_this, dict(__file__=activate_this))



#import pip
# FIXME: when running freeze, got all SYSTEM packages and not only
#        the current venv list :/ Must use the pip function.

   
print "Using " + pip('--version')

req_file=os.path.join(django_venv, 'requirements.txt')

if os.path.isfile(req_file):
    print "Installing pkg from %s file\n" % req_file
    print pip('install', '-r',req_file, '--upgrade') 
else:
    print "Installing Django%s ...\n" % django_version 
    print pip('install', 'Django'+django_version)

print "Updating requirements file %s\n" % req_file
reqs = pip('freeze')
print reqs

open(req_file, 'w').write(reqs)


print "Testing Django installation\n"
try:
    import django
    print "Django version: " + django.get_version()
except:
    print "Installation Error; can't import django"


print "\n\nThat's all flolks. Let's have fun\n"



