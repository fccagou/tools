#!/bin/env python

import os
import re
import sys




class Set(object):

    def __init__(self, name), values=[]:
        self.name = name
        self.values = values

    def __repr__(self):
        print ("{0} {\n    {1}\n};".format(self.name, "\n    ".join(self.values)))



class NamedConfig(object):
    """bind named configuration parser

       Parse file beautified by named-checkconf -p named.conf
    """
    include_parser = re.compile('\s*include\s+"([^"]*)"\s*;\s*')
    #  set "name" {
    #
    #  };
    parser_set_named = re.compile('\s*(\W+)\s+"([^"]+)"\s*{\s*')

    #  set {
    #
    #  };
    parser_set = re.compile('\s*(\W+)\s*{\s*')

    # value;
    parser_value = re.compile('\s*(\W+)\s*;\s*')

    # key value;
    parser_key_value = re.compile('\s*(\W+)\s+(\W+)\s*;\s*')
    def __init__(self):
        self.views=[]
        self.files={}
        self.acls=[]
        self.data={}


        self.current_view = None
        self.current_zone = None

    def addView(self, v):
        self.views.append(v)

    def addFile(self, f):
        if f.name not in self.files:
            self.files[f.name] = f

    @staticmethod
    def stringset2list(s):
        return [ a.strip() for a in s.strip().split(';') if len(a)>0]


    def parse_file(self, filename, prexix='.'):
        if filename[0] == os.path.sep:
            fullname = os.path.abspath(os.path.expanduser(filename))
        else:
            fullname = os.path.abspath(os.path.join(prefix,filename))

        try:
            with open(fullname) as f:
                self.parse(f,prefix)

        except FileNotFoundError:
            print("Can't access file {0}".format(fullname))

        except:
            print("Error parsing {0}".format(fullname))
            import traceback
            print('-'*60)
            traceback.print_exc(file=sys.stdout)
            print('-'*60)


    def parse(self, f, prefix='.'):

        try:
                for l in f.readlines():

                    m = self.include_parser.match(l)
                    if m is not None:
                        self.parse_file(m.group(1), prefix)
                        continue

                    m = self.parser_set_named(l)
                    if m is not None:
                        set_type = m.group(1)
                        set_name = m.group(2)

                        if set_type == 'acl':
                            for l in f.readlines():



        except:
            print("Error parsing {0}".format(fullname))
            import traceback
            print('-'*60)
            traceback.print_exc(file=sys.stdout)
            print('-'*60)


    def parse_prev(self, filename, prefix='.'):

        if filename[0] == os.path.sep:
            fullname = os.path.abspath(os.path.expanduser(filename))
        else:
            fullname = os.path.abspath(os.path.join(prefix,filename))

        try:
            with open(fullname) as f:
                for l in f.readlines():

                    m = NamedConfig.include_parser.match(l)
                    if m is not None:
                        self.parse(m.group(1), prefix)
                        continue

                    if self.current_view is None:
                        # In file header
                        m = Acl.parser.match(l)
                        if m is not None:
                            self.acls.append(Acl(m.group(1), NamedConfig.stringset2list(m.group(2))))
                            continue

                    # Check view
                    m = View.parser.match(l)
                    if m is not None:
                        if self.current_view is not None:
                            if self.current_zone is not None:
                                self.current_view.addZone(self.current_zone)
                                self.current_zone = None
                            self.addView(self.current_view)
                        self.current_view = View(m.group(1))
                        continue

                    if self.current_zone is None:
                        m = View.match_clients_parser.match(l)
                        if m is not None:
                            self.current_view.match_clients = NamedConfig.stringset2list(m.group(1))
                            continue

                    # TODO: verify if this parameter is also ini zone.
                    m = View.also_notify_parser.match(l)
                    if m is not None:
                        if self.current_zone is not None:
                            self.current_zone.also_notify = NamedConfig.stringset2list(m.group(1))
                        else:
                            self.current_view.also_notify = NamedConfig.stringset2list(m.group(1))
                        continue

                    m = View.allow_transfer_parser.match(l)
                    if m is not None:
                        if self.current_zone is not None:
                            self.current_zone.allow_transfer = NamedConfig.stringset2list(m.group(1))
                        else:
                            self.current_view.allow_transfer = NamedConfig.stringset2list(m.group(1))
                        continue

                    m = View.allow_query_parser.match(l)
                    if m is not None:
                        if self.current_zone is not None:
                            self.current_zone.allow_query = NamedConfig.stringset2list(m.group(1))
                        else:
                            self.current_view.allow_query = NamedConfig.stringset2list(m.group(1))
                        continue

                    # check zone
                    m = Zone.parser.match(l)
                    if m is not None:
                        if self.current_zone is not None:
                            self.current_view.addZone(self.current_zone)
                        self.current_zone = Zone(m.group(1))
                        continue

                    # check zone type
                    m = Zone.type_parser.match(l)
                    if m is not None:
                        self.current_zone.type = m.group(1)
                        continue

                    # check zone master
                    m = Zone.masters_parser.match(l)
                    if m is not None:
                        masters = NamedConfig.stringset2list(m.group(1))
                        if self.current_zone is None:
                            self.masters = masters
                        else:
                            self.current_zone.masters = masters
                        continue

                    # check file
                    m = ZoneFile.parser.match(l)
                    if m is not None and self.current_zone is not None:
                        f = ZoneFile(m.group(1),m.group(1))
                        self.current_zone.file = f.name
                        if self.current_zone.type == 'master':
                            f.parse(prefix)
                        self.addFile(f)
                        continue


            if self.current_view is not None:
                if self.current_zone is not None:
                    self.current_view.addZone(self.current_zone)
                self.addView(self.current_view)
        except FileNotFoundError:
            print("Can't access file {0}".format(fullname))

        except:
            print("Error parsing {0}".format(fullname))
            import traceback
            print('-'*60)
            traceback.print_exc(file=sys.stdout)
            print('-'*60)




class Acl(object):
    parser = re.compile('\s*acl\s+"([^"]+)"\s+{\s*([^}]*)\s*}\s*;\s*')
    def __init__(self, name, members=[]):
        self.name = name
        self.members = members

    def __str__(self):
        return 'acl {0}\n    {1}'.format(self.name, "\n    ".join(self.members))






class View(object):
    parser = re.compile('^view\s+"([^"]*)".*')
    match_clients_parser = re.compile('\s*match-clients\s+{\s*([^}]*)\s*}\s*;\s*')
    also_notify_parser = re.compile('\s*also-notify\s+{\s*([^}]*)\s*}\s*;\s*')
    allow_transfer_parser = re.compile('\s*allow-transfer\s+{\s*([^}]*)\s*}\s*;\s*')
    allow_query_parser = re.compile('\s*allow-query\s+{\s*([^}]*)\s*}\s*;\s*')
    def __init__(self,name, zones=[]):
        self.name = name
        self.zones = zones
        self.match_clients = []
        self.also_notify = []
        self.allow_transfer = []
        self.allow_query = []


    def addZone(self, z):
        self.zones.append(z)

    def __str__(self):
        return 'view {0}\n  Allow From: {1}\n  also-notify: {2}\n  allow-transfer: {3}\n  allow-query: {4}'.format(
            self.name, ", ".join(self.match_clients), ', '.join(self.also_notify), ', '.join(self.allow_transfer), ', '.join(self.allow_query)
        )







class Zone(object):
    parser = re.compile('\s*zone\s+"([^"]*)".*')
    type_parser = re.compile('\s*type\s+([^\s]*)\s*;\s*')
    masters_parser = re.compile('\s*masters\s*{\s*([^}]*)\s*}\s*;\s*')
    def __init__(self, name):
        self.name = name
        self.type = None
        self.file = None
        self.masters = []
        self.domain = None
        self.subnet = None
        self.network_from_name()
        self.also_notify = []
        self.allow_transfer = []
        self.allow_query = []

    def is_direct(self):
        return self.domain is not None

    def network_from_name(self):
        dots = self.name.split('.')
        if dots[-1] == 'arpa':
            dots = dots[:-2]
            dots.reverse()
            self.subnet = '.'.join(dots)
        else:
            self.domain = self.name

    def __str__(self):
        if self.is_direct():
            d_type = 'domain'
            display = self.domain
        else:
            d_type = 'network'
            display = self.subnet
        # TODO: conditional display
        return 'zone {0} ({1})\n    {2}\n    {3}\n    {4}: {5}\n  also-notify: {6}\n  allow-transfer: {7}\n  allow-query: {8}'.format(
            self.name, self.type, ", ".join(self.masters),self.file, d_type, display, ', '.join(self.also_notify), ', '.join(self.allow_transfer), ', '.join(self.allow_query))




class ZoneFile(object):
    parser = re.compile('\s*file\s+"([^"]*)".*')

    def __init__(self, name, path=""):
        self.name = name
        self.path = path

    def __str__(self):
        return "{0} => {1}".format(self.name, self.path)


    def parse(self, prefix='.'):
        """Parse zone file"""
        fullname = os.path.join(prefix,self.path)
        try:
            with open(fullname) as f:
                for l in f.readlines():
                    print(l.strip())
        except FileNotFoundError:
            print("Can't access zone file {0}".format(fullname))
        except:
            print("Error parsing zone file {0}".format(fullname))
            import traceback
            print('-'*60)
            traceback.print_exc(file=sys.stdout)
            print('-'*60)


if __name__ == '__main__':

    # TODO:
    # - gerer le cas des retours a la ligne.

    nc = NamedConfig()
    prefix = os.path.dirname(sys.argv[1])
    conf_file = os.path.basename(sys.argv[1])

    nc.parse_file(conf_file, prefix)



    print ("""
    **********************************************************************************************

          #    #    ##    #     #  #####  #####
          #    #   #  #   ##   ##  #       #   #
          ##   #  #    #  # # # #  #       #   #
          # #  #  #    #  #  #  #  #       #   #
          #  # #  #    #  #     #  ####    #   #
          #   ##  ######  #     #  #       #   #
          #    #  #    #  #     #  #       #   #
          #    #  #    #  #     #  #       #   #
          #    #  #    #  #     #  #####  #####


    **********************************************************************************************
    """)

    print(nc)

#     for a in nc.acls:
#         print(a)
#
#     print ('\n')
#
#     for v in nc.views:
#         print (v)
#         for z in v.zones:
#             print ("  {0}\n".format(z))
#

