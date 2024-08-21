#!/usr/bin/bash

prefix="$(readlink -f "$(dirname "$0")")"


export BATCHMODE=yes
export CA_DIR=/tmp/mytest
export C="VU"
export ST="Tanna"
export L="Lenakel"
export O="Kava Inc"
export OU="IT blong $O"
export CN="CA blong $O"

export PATH="$prefix"/..:"$PATH"

hosts=( host1.local host2.local, host3.local)

pki init
for h in "${hosts[@]}"; do
   pki request new "$h"
   pki cert sign "$h"
done
pki status

pki status | \
	grep -E '^(------- |serial=|subject=|issuer=)' > "${CA_DIR}"/test-status
cat -> ${CA_DIR}/test-status-ref <<EOF_REF
------- (${CA_DIR}/newcerts/1000.pem)
serial=1000
subject=C=VU, ST=Tanna, O=Kava Inc, OU=IT blong Kava Inc, CN=host1.local
issuer=C=VU, ST=Tanna, L=Lenakel, O=Kava Inc, OU=IT blong Kava Inc, CN=CA blong Kava Inc
------- (${CA_DIR}/newcerts/1001.pem)
serial=1001
subject=C=VU, ST=Tanna, O=Kava Inc, OU=IT blong Kava Inc, CN=host2.local,
issuer=C=VU, ST=Tanna, L=Lenakel, O=Kava Inc, OU=IT blong Kava Inc, CN=CA blong Kava Inc
------- (${CA_DIR}/newcerts/1002.pem)
serial=1002
subject=C=VU, ST=Tanna, O=Kava Inc, OU=IT blong Kava Inc, CN=host3.local
issuer=C=VU, ST=Tanna, L=Lenakel, O=Kava Inc, OU=IT blong Kava Inc, CN=CA blong Kava Inc
EOF_REF

diff "${CA_DIR}"/test-status "${CA_DIR}"/test-status-ref >/dev/null 2>&1 && echo "status OK" || {
	echo "status ERROR" >&2
    diff "${CA_DIR}"/test-status "${CA_DIR}"/test-status-ref >&2
}
