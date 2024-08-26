#!/bin/bash

set -euo pipefail

# Variables de configuration
prefix="$(readlink -f "$(dirname "$0")")"
confloader="$prefix"/pki-config-load.sh
CA_DIR="${CA_DIR:-./myCA}"

cat <<'EOF_DOC' | less
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

## Automation for tests

```bash
   export BATCHMODE=yes
   export C="AU"
   export ST="Queensland"
   export L="Brisbane"
   export O="Lamington's Inc."
   export OU="IT of $O"
   export CN="CA of $O"

   hosts=( host1.local host2.local host3.local)
   pki init
   for h in "${hosts[@]}"; do
       pki request new "$h"
       pki cert sign "$h"
   done
   pki status
```

## Containers

Build

```bash
     docker build -t . pki
```

Simple usage creating default myCA in current dir

```bash
    docker run -ti --rm  -v.:/pki pki init
```

Use Docker or Podman's `-e | --env`parameters to set pki configurations

```bash
    docker run -ti --rm  -v.:/pki \
       --env CA_DIR=/pki/lamingtonCA \
       --env BATCHMODE=yes \
       --env C="AU" \
       --env ST="Queensland" \
       --env L="Brisbane" \
       --env O="Lamington's Inc." \
       --env OU="IT of Lamington's Inc." \
       --env CN="CA of Lamington's Inc." \
	   pki init
```
EOF_DOC
