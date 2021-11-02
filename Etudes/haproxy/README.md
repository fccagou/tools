Hum ... some tries to use haproxy on localhost for transparent proxy.

    iptables -t mangle -N DIVERT
    iptables -t mangle -A PREROUTING -p tcp -m socket -j DIVERT
    iptables -t mangle -A DIVERT -j MARK --set-mark 1
    iptables -t mangle -A DIVERT -j ACCEPT


    ip rule add fwmark 1 lookup 100
    ip route add local 0.0.0.0/0 dev lo table 100


    frontend ft_application
       bind 1.1.1.1:80 transparent

    backend bk_application
       source 0.0.0.0 usesrc clientip
