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
pki cert request myhost.local
# Sign certificat
pki cert sign myhost.local.csr
```
