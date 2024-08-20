#PKI

## Description

Simple bash scripts to manage PKI with openssl.

These are test scripts to manipulate openssl
and understand the mechanisms for managing a PKI.

## Attention

Secrets management is not done properly
for production use, unless it is for
generate test or qualification environments.

##Quickstart

```bash
    # Add completion to your environment
    . pki-completion.sh

    # Initialize the pki
    pki init

    # Create a certificate request for server myhost.local
    pki request new myhost.local

    # Check the list of certificates awaiting signature
    pki requests

    # Sign pending certificate for myhost.local
    pki cert sign myhost.local

    # Show list of pki certificates
    pki certs

    # Check the status of a certificate by giving the file path
    pki cert status ./myCA/certs/myhost.local.pem

    # or use a serial number
    pki cert status 1000

    # Global status
    pki status
```

More help

```bash
    pki help <TAB> <TAB>
```
