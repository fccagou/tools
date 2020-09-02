#!/bin/env python

import os
import re



class NamedConfig(object):
    """bind named configuration parser"""
    include_parser = re.compile('\s*include\s+"([^"]*)"\s*;\s*')
    def __init__(self):
        self.views=[]
        self.files={}
        self.files={}
        self.acls=[]

    def addView(self, v):
        self.views.append(v)

    def addFile(self, f):
        if f.name not in self.files:
            self.files[f.name] = f

    @staticmethod
    def stringset2list(s):
        return [ a.strip() for a in s.strip().split(';') if len(a)>0]

    def parse(self, filename, prefix='.'):

        current_view = None
        current_zone = None
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

                    if current_view is None:
                        # In file header
                        m = Acl.parser.match(l)
                        if m is not None:
                            self.acls.append(Acl(m.group(1), NamedConfig.stringset2list(m.group(2))))
                            continue

                    # Check view
                    m = View.parser.match(l)
                    if m is not None:
                        if current_view is not None:
                            if current_zone is not None:
                                current_view.addZone(current_zone)
                                current_zone = None
                            self.addView(current_view)
                        current_view = View(m.group(1))
                        continue

                    if current_zone is None:
                        m = View.match_clients_parser.match(l)
                        if m is not None:
                            current_view.match_clients = NamedConfig.stringset2list(m.group(1))
                            continue

                    # TODO: verify if this parameter is also ini zone.
                    m = View.also_notify_parser.match(l)
                    if m is not None:
                        if current_zone is not None:
                            current_zone.also_notify = NamedConfig.stringset2list(m.group(1))
                        else:
                            current_view.also_notify = NamedConfig.stringset2list(m.group(1))
                        continue

                    m = View.allow_transfer_parser.match(l)
                    if m is not None:
                        if current_zone is not None:
                            current_zone.allow_transfer = NamedConfig.stringset2list(m.group(1))
                        else:
                            current_view.allow_transfer = NamedConfig.stringset2list(m.group(1))
                        continue

                    m = View.allow_query_parser.match(l)
                    if m is not None:
                        if current_zone is not None:
                            current_zone.allow_query = NamedConfig.stringset2list(m.group(1))
                        else:
                            current_view.allow_query = NamedConfig.stringset2list(m.group(1))
                        continue

                    # check zone
                    m = Zone.parser.match(l)
                    if m is not None:
                        if current_zone is not None:
                            current_view.addZone(current_zone)
                        current_zone = Zone(m.group(1))
                        continue

                    # check zone type
                    m = Zone.type_parser.match(l)
                    if m is not None:
                        current_zone.type = m.group(1)
                        continue

                    # check zone master
                    m = Zone.masters_parser.match(l)
                    if m is not None:
                        masters = NamedConfig.stringset2list(m.group(1))
                        if current_zone is None:
                            self.masters = masters
                        else:
                            current_zone.masters = masters
                        continue

                    # check file
                    m = ZoneFile.parser.match(l)
                    if m is not None and current_zone is not None:
                        f = ZoneFile(m.group(1),m.group(1))
                        current_zone.file = f.name
                        if current_zone.type == 'master':
                            f.parse(prefix)
                        self.addFile(f)
                        continue


            if current_view is not None:
                if current_zone is not None:
                    current_view.addZone(current_zone)
                self.addView(current_view)
        except:
            print("Error parsing {0}".format(fullname))





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
        try:
            with open(os.path.join(prefix,self.path)) as f:
                pass
                #for l in f.readlines():
                #    print(l.strip())
        except:
            print("Error Parsing {0}".format(os.path.join(prefix,self.path)))




# TODO:
# - gerer le cas des retours a la ligne.

nc = NamedConfig()
nc.parse('named.conf')



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

for a in nc.acls:
    print(a)

print ('\n')

for v in nc.views:
    print (v)
    for z in v.zones:
        print ("  {0}\n".format(z))


