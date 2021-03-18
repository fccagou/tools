# best-service

Quick and dirty tool to check best connect time between many services:

Some links:
- https://github.com/nephilimboy/Python-LoadBalancer


# Usages
    
    $ ./check_net_service.py -h
    usage: check_net_service.py [-h] [--verbose] [--threshold THRESHOLD]
                                [--no-store] [--last-used-store LAST_USED_STORE]
                                [--last-used-first] [--algo {fastest,first_up}]
                                service [service ...]
    
    Net Service Checker
    
    positional arguments:
      service               list of services to check in forme host:port
    
    optional arguments:
      -h, --help            show this help message and exit
      --verbose, -v         verbose.
      --threshold THRESHOLD, -t THRESHOLD
                            Threshold for acceptable service (float).
      --no-store            Do not store lastused service
      --last-used-store LAST_USED_STORE
                            File pasth used to store lastused service (default:
                            ~/.check_services)
      --last-used-first     Use last first
      --algo {fastest,first_up}, -a {fastest,first_up}
                            Check algorithm (default: fastest)


Get the quicker service

     python ./check_net_service.py -v  www.google.com:80 localhost:8081


Get the first responding

     python ./check_net_service.py -v --algo first_up www.google.com:80 localhost:8081
     python ./check_net_service.py -v --algo first_up toto:123 www.google.com:80 localhost:8081

First try lastused service sored in last-used-store.

     python ./check_net_service.py -v --last-used-first   --algo first_up toto:123 www.google.com:80 localhost:8081
     python ./check_net_service.py -v --last-used-first   --algo toto:123 www.google.com:80 localhost:8081
     python ./check_net_service.py -v --last-used-first  toto:123 www.google.com:80 localhost:8081
     python ./check_net_service.py -v --last-used-first  toto:123 www.google.com:80 localhost:8081
     python ./check_net_service.py -v --last-used-first  --algo first_up toto:123 www.google.com:80 localhost:8081
     python ./check_net_service.py -v --last-used-first  toto:123 www.google.com:80 localhost:8081

Try unreadeable store to test errors

     python ./check_net_service.py -v --last-used-store /root/titi toto:123 www.google.com:80 localhost:8081

     python ./check_net_service.py -v toto:123 www.google.com:80 localhost:8081
     python ./check_net_service.py -v --last-used-first toto:123 www.google.com:80 localhost:8081
     python ./check_net_service.py -v --last-used-first toto:123 www.google.com:80 localhost:8081
     python ./check_net_service.py -v --last-used-first toto:123 www.google.com:80 localhost:8081


Test no result store

     python ./check_net_service.py -v  --no-store --last-used-first toto:123 www.google.com:80 localhost:8081
     python ./check_net_service.py -v toto:123 www.google.com:80 localhost:8081
     python ./check_net_service.py -v --no-store toto:123 www.google.com:80 localhost:8081
     python ./check_net_service.py -v --last-used-store /tmp/toto --no-store toto:123 www.google.com:80 localhost:8081
     python ./check_net_service.py -v --last-used-store /tmp/toto  toto:123 www.google.com:80 localhost:8081
     python ./check_net_service.py -v --last-used-store /tmp/toto  --last-used-first toto:123 www.google.com:80 localhost:8081
     python ./check_net_service.py -v --last-used-store /tmp/toto  toto:123 www.google.com:80 localhost:8081
     python ./check_net_service.py -v --algo first_up toto:123 www.google.com:80 localhost:8081


