#!/usr/bin/bash

set -euo pipefail

usage () {
	local cmd
	cmd="${0##*/}"
	cmd="${cmd//-/ }"
    cmd="${cmd%%.sh}"
    cat <<EOF_USAGE

--------------------------------------------------------------------------------

       @@@@   @  @   @@@
       @   @  @ @     @
       @@@@   @@      @
       @      @ @     @
       @      @  @    @
       @      @   @  @@@        Ensemble de commandes pour gérer une PKI.

--------------------------------------------------------------------------------

ATTENTION:

  Ces scripts servent à étudier le fonctionnement d'une pki et ne prennent pas
  en compte les précautions de sécurité concernant la gestion de la clé privée
  de la CA. Dans ce contexte, ils peuvent être utilisés pour monter des infras
  de tests.

--------------------------------------------------------------------------------

Pour commencer, ajouter la completion à votre environnement

    . ./pki-completion.sh

Usage: $cmd COMMAND

COMMANDs:

$(
  cd "$prefix" \
  && ls -1 pki-*.sh \
     | sort -V \
	 | grep -v help.sh  \
	 | sed -e 's/^pki-//' -e 's/-/ /g' -e 's/.sh$//'  \
	 | awk '{ print "     "$0 }'
)

Pour aller plus loin

    pki doc <fr|en>

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
