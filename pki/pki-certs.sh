#!/bin/bash

set -euo pipefail

# Variables de configuration
CA_DIR="${CA_DIR:-./myCA}"

for f in "${CA_DIR}"/newcerts/*.pem;  do
	echo "-------"
	tmp="${f##*/}"
	echo "serial=${tmp%%.pem}"
	openssl x509 -in "$f" -subject -issuer -dates -noout
done

