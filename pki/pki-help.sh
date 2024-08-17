#!/usr/bin/bash

set -euo pipefail

usage () {
	local cmd
	cmd="${0##*/}"
	cmd="${cmd//-/ }"
    cmd="${cmd%%.sh}"
    cat <<EOF_USAGE
Usage: $cmd COMMAND

COMMAND:

$(
  cd "$prefix" \
  && ls -1 pki-*.sh \
     | sort -V \
	 | grep -v help.sh  \
	 | sed -e 's/^pki-//' -e 's/-/ /g' -e 's/.sh$//'  \
	 | awk '{ print "     "$0 }'
)

EOF_USAGE
}

prefix="$(dirname "$0")"
# Paramètres d'entrée
if [ "$#" == "0" ]; then
	usage
    exit 0
fi


printf -v fullname -- '-%s' "$@"

[ -f "$prefix"/pki"$fullname".sh ] && "$prefix"/pki"$fullname".sh --help
