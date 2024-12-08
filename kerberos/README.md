# Kerberos

## Abstract

Some kerberos tools in docker for tests


## Quickstart

Clone repository and compose up

```bash
git clone https://gitlab.com/fccagou/tools
cd kerberos
docker compose build
docker compose up -d
```

Test

    export KRB5_CONFIG="$(pwd)"/krb5.conf
    export KRB5CCNAME=/dev/shm/kerberos_user_cache
    kinit user@EXAMPLE.COM
    curl  --negotiate -u : http://localhost:8880/private/test.txt
    Private acces OK


## Kerberos server

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

## Persistent data

Create volume and use subpath

    docker volume create mykdc
    docker run -ti --rm -v mykdc:/mnt alpine mkdir -p /mnt/{conf,db,keytabs}
    docker run -d --name mykdc  \
        --mount src=mykdc,destination=/var/krb5kdc,volume-subpath=conf\
        --mount src=mykdc,destination=/var/lib/krb5kdc,volume-subpath=db\
        --mount src=mykdc,destination=/srv/keytabs,volume-subpath=keytabs\
        -p 8888:88 kerberos:alpine

Create keytab

    docker exec -ti mykdc  kadmin.local addprinc -randkey HTTP/localhost@EXAMPLE.COM
    docker exec -ti mykdc  kadmin.local ktadd -k /srv/keytabs/http-localhost.keytab  HTTP/localhost@EXAMPLE.COM


## Apache kerberos server

Build image

    docker build -t apache:krb -f Dockerfile-http .

Run web server

    KDC_IP="$(docker container inspect mykdc --format '{{.NetworkSettings.IPAddress}}')"
    docker run -ti --rm -p 8880:80 \
        --mount src=mykdc,dst=/etc/apache2/keytabs,volume-subpath=keytabs \
        --add-host kerberos.example.com:"${KDC_IP}"  \
        apache:krb -C 'serverName localhost'


Test

    export KRB5_CONFIG="$(pwd)"/krb5.conf
    kinit user@EXAMPLE.COM
    curl  --negotiate -u : http://localhost:8880/private/test.txt
    Private acces OK


Show kerberos tickets

    klist 
    Ticket cache: FILE:/tmp/krb5cc_1000
    Default principal: user@EXAMPLE.COM
    
    Valid starting       Expires              Service principal
    07/12/2024 18:26:36  08/12/2024 18:26:36  krbtgt/EXAMPLE.COM@EXAMPLE.COM
            renew until 07/12/2024 18:26:36
    07/12/2024 18:39:31  08/12/2024 18:26:36  HTTP/localhost@
            renew until 07/12/2024 18:26:36
            Ticket server: HTTP/localhost@EXAMPLE.COM

## TODO

-[ ] add args and .env feature to build other realm.
