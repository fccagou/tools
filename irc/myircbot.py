#!/usr/bin/env python3

import sys
import re
import socket
import string
import time

from  urllib import request


def info(msg):
   print("[+] {0}".format(msg))





class IRC:

    # Defaults values
    irc_server="localhost"
    irc_port=6667
    irc_channel="#tuxoncloud"
    my_master="fccagou"
    my_irc_nick="cagoubot"
    my_irc_user="cagoubot"
    my_irc_realname="Cagou Bot"

    # IRC protcol.
    #:fccagou!fccagou@localhost PRIVMSG toto :hello man
    irc_privmsg = re.compile(":([^!]*)!([^@]*)@([a-z\.-]*) PRIVMSG ([^ ]*) :(.*)")
    #:fccagou!fccagou@localhost JOIN :#tuxoncloud
    irc_join = re.compile(":([^!]*)!([^@]*)@([a-z\.-]*) JOIN :(.*)")
    #:fccagou!fccagou@localhost QUIT :"leaving"
    irc_quit = re.compile(":([^!]*)!([^@]*)@([a-z\.-]*) QUIT :(.*)")
    # :opium.gin.local 353 toto = #tuxoncloud :toto
    irc_names = re.compile(":([^ ]*) ([^ ]*) ([^ ]*) = ([^ ]*) :(.*)")

    events_level = {
            'none': 0,
            'talk': 10,
            'join': 50,
            'master_present': 100,
     }


    def __init__(self, irc_server="localhost", irc_port=6667, irc_channel="#tuxoncloud",
            my_master="fccagou", my_irc_nick="cagoubot", my_irc_user="cagoubot", my_irc_realname="Cagou Bot",
            pyap_url=None):
        self.irc_server = irc_server
        self.irc_port = irc_port
        self.irc_channel = irc_channel
        self.my_master = my_master
        self.my_irc_nick = my_irc_nick
        self.my_irc_user = my_irc_user
        self.my_irc_realname = my_irc_realname
        self.is_my_master_connected = False
        self.socket = None
        self.readbuffer = ""
        self.nb_hello_master = 0
        self.last_event = IRC.events_level['none']
        self.pyap_url = pyap_url

    def connect(self):
        info("Server {0}:{1} connection...".format(self.irc_server, self.irc_port))
        self.socket=socket.socket( )
        self.socket.connect((self.irc_server, self.irc_port))

    def _send(self,msg):
        info(" >> {0}".format(msg))
        self.socket.send(bytes("{0}\r\n".format(msg), "UTF-8"))

    def _recv(self):
        self.readbuffer = self.readbuffer+self.socket.recv(1024).decode("UTF-8")
        data = str.split(self.readbuffer, "\n")
        self.readbuffer = data.pop()
        return data

    def send_nick(self):
        self._send("NICK {0}".format(self.my_irc_nick))

    def send_user(self):
        self._send("USER {0} {1} bla :{2}".format(self.my_irc_user, self.irc_server, self.my_irc_realname))


    def send_mesg(self, to, msg):
        self._send("PRIVMSG {0} :{1}".format(to, msg))


    def talk_to_master(self, msg):
        if self.is_my_master_connected:
            self.send_mesg(self.my_master, msg)

    def pong(self, msg):
        self._send("PONG {0}".format(msg))

    def hello_master(self, tempo=0):
        if tempo > 0:
            info("Tempo before talking to master({0} s)...".format(tempo))
            time.sleep(tempo)

        info("Say hello to master {0}".format(self.my_master))
        if self.nb_hello_master == 0:
            self.talk_to_master("Hello {0}, how are U today ?".format(self.my_master, self.my_irc_nick))
            self.nb_hello_master = self.nb_hello_master + 1
        else:
            self.talk_to_master("Welcome back {0}, I missed U !".format(self.my_master, self.my_irc_nick))


    def join(self):
        self._send("JOIN {0}".format(self.irc_channel))
        self.wait_until ("End of NAMES list")
        if self.is_my_master_connected:
            self.hello_master(tempo=3)

    def wait_until(self, msg):
        info("Waiting server replies ({0})...".format(msg))
        not_found = True
        while not_found:

            for line in self._recv():
                line = str.rstrip(line)
                print("[<] {0}".format(line))
                if line.find(msg) > 0:
                    not_found = False
                    break

                if not self.is_my_master_connected:
                    m = IRC.irc_names.match(line)
                    self.is_my_master_connected = m and self.my_master in m[5]

                    if self.is_my_master_connected:
                        self.notify_master_present()


    def external_notify(self, event_type):
        if self.last_event != event_type:
            self.last_event = event_type
            self.pyap_notify(self.last_event)

    def notify_master_present(self):
        self.external_notify('master_present')

    def notify_new_join(self):
        self.external_notify('join')

    def notify_new_talk(self):
        if 'master_present' == self.last_event or IRC.events_level['talk'] > IRC.events_level[self.last_event]:
            self.external_notify('talk')

    def pyap_notify(self, status):
        if self.pyap_url is not None:
            status_list = {
                    'none': 'unknown',
                    'master_present': 'security/ack ok',
                    'join': 'security/ack critical security',
                    'talk': 'security/ack warning security'
            }

            for s in status_list[status].split():
                try:
                    f = request.urlopen("{0}/{1}".format(self.pyap_url,s))
                    f.close()
                    time.sleep(0.5)
                except:
                    info('Notification error ({0})'.format(s))


    def serve(self):

        while 1:
            for line in self._recv():
                line = str.rstrip(line)
                print("<< {0}".format(line))

                if line.find("PING") == 0:
                    self.pong(line.split()[1])

                if line.find("JOIN") > 0:
                    m = IRC.irc_join.match(line)
                    if m and m[2] == self.my_master:
                        info("My master is joining")
                        self.is_my_master_connected = True
                        self.notify_master_present ()
                    else:
                        self.notify_new_join ()

                if line.find("QUIT") > 0:
                    m = IRC.irc_quit.match(line)
                    if m and m[2] == self.my_master:
                        info("Saaaad, My master quit {0}".format(m[4]))
                        self.is_my_master_connected = False

                if line.find("PRIVMSG") > 0:
                    info("Who commands ?")
                    m = IRC.irc_privmsg.match(line)
                    if not m:
                       print("[-] REGEX ERROR")
                    else:
                       # print("nick: {0}\nUser: {1}\nHost: {2}\nDest: {3}\nMsg: {4}".format(m.group(1), m.group(2), m.group(3), m.group(4), m.group(5)))
                       from_nick = m[1]
                       from_user = m[2]
                       from_host = m[3]
                       to = m[4]
                       from_msg = m[5]

                       if from_user == self.my_master:
                           # Message from master
                           self.notify_master_present ()
                           if to == self.my_irc_nick:
                               # Is talking to me
                               if not self.is_my_master_connected:
                                   # TODO: improve the case
                                   info("WARNING Got a msg from master when not connected ...")
                                   self.is_my_master_connected = True
                                   self.hello_master()

                               # Checking the question
                               if "clear notification" in from_msg:
                                   self.last_event = 'none'
                                   self.notify_master_present ()
                               else:
                                   self.talk_to_master("Hum ... What do U mean by {0}".format(from_msg))

                       else:
                          self.notify_new_talk ()
                          # Someone else talking
                          if to == self.my_irc_nick:
                              # I fo not speak to unknown person.
                              info("{0} is not my master !!".format(from_user))
                              self.talk_to_master("ALERT {0} ".format(m[0]))



def main( irc_bot ):

    server_connect_tempo=3

    irc_bot.connect()
    irc_bot.send_nick()
    irc_bot.send_user()

    info("Waiting server replies ({0} s)...".format(server_connect_tempo))
    time.sleep(server_connect_tempo)

    irc_bot.join()
    irc_bot.serve()





if __name__ == '__main__':

    # Process passed arguments.
    try:
        import argparse
        parser = argparse.ArgumentParser(
            description='My IRC Bot',
            )
        USING_ARGPARSE = True
    except ImportError:
        import optparse
        parser = optparse.OptionParser(
            description='My IRC Bot.')
        parser.parse_args_orig = parser.parse_args
        parser.parse_args = lambda: parser.parse_args_orig()[0]
        parser.add_argument = parser.add_option
        USING_ARGPARSE = False

    parser.add_argument('--server', '-s', default = IRC.irc_server,
                        help="irc server ({0})".format(IRC.irc_server))
    parser.add_argument('--port', '-p', default = IRC.irc_port,
                        help="irc port ({0})".format(IRC.irc_port))
    parser.add_argument('--ircchannel', '-c', default = IRC.irc_channel,
                        help="irc channel ({0})".format(IRC.irc_channel))
    parser.add_argument('--mymaster', '-m', default = IRC.my_master,
                        help="Got only one master ({0}) <3".format(IRC.my_master))
    parser.add_argument('--myircnick', '-n', default = IRC.my_irc_nick,
                        help="My irc nick ({0})".format(IRC.my_irc_nick))
    parser.add_argument('--myircuser', '-u', default = IRC.my_irc_user,
                        help="My irc user ({0})".format(IRC.my_irc_user))
    parser.add_argument('--myircrealname', '-r', default = IRC.my_irc_realname,
                        help="My irc real name ({0})".format(IRC.my_irc_realname))

    parser.add_argument('--pyapurl', default = None,
                        help="Define pyap url notifier (default is None)")

    args = parser.parse_args()

    irc_bot = IRC( irc_server=args.server
            ,irc_port=args.port
            ,irc_channel=args.ircchannel
            ,my_master=args.mymaster
            ,my_irc_nick=args.myircnick
            ,my_irc_user=args.myircuser
            ,my_irc_realname=args.myircrealname
            ,pyap_url = args.pyapurl
            )

    main(irc_bot)

    os._exit(os.EX_OK)

