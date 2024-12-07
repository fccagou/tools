# Kerberos

## Abstract

Some kermeros tools in docker for tests


## Quickstart

Build image


    docker build -t kerberos:alpine -f Dockerfile-kdc .


Run container

    docker run -p 8888:88 --name mykdc kerberos:alpine

Test

    (export KRB5_CONFIG="$(pwd)"/krb5.conf; kinit user@EXAMPLE.COM )


Admin

    docker exec -ti mykdc kadmin.local getprincs
    K/M@EXAMPLE.COM
    kadmin/admin@EXAMPLE.COM
    kadmin/changepw@EXAMPLE.COM
    krbtgt/EXAMPLE.COM@EXAMPLE.COM
    user@EXAMPLE.COM


Enjoy    
