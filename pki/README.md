# PKI

## Description

Simple bash scripts to manage CA using openssl

## Quickstart

```bash
# add bash completion
. pki-completion.sh

# Initialize CA
pki init
# Creates certificat request for myhost.local
pki request new myhost.local
# Sign certificat
pki cert sign myhost.local.csr
# List pki knowns certificats
pki certs
# verify certificat status using path to filename
pki cert status myhost.local.pem
# or use a serial number
pki cert status 1000
```

More help

```bash
pki help any command
```

