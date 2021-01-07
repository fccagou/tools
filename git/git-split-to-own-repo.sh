#!/bin/sh

# This file is part of fccagou's tools.
# Copyright 2019 fccagou <fccagou@gmail.com>
#
# Those tools are free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Those tools are distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
# License for more details.
#
# You should have received a copy of the GNU General Public License
# along with IVRE. If not, see <http://www.gnu.org/licenses/>.
#
#
#
# Objectif: associer un dépot git autonome pour chaque module puppet 
#           présents dans un même dépôt Git
#
# Contraintes:
# * conserver l'historique
# * avoir une nommenclature standard pour les dépots bare
#
#
# * la branche dans le dépôt bare est master
# * il faut créer un tag pour marqué le moment du split vYYYYMMDD
#
# Git a un outil pour faire cela, il s'agit de subtree. La commande utilisée sera de la forme
#
#   git subtree split -P modules/xxxxx -b xxxx
#
# Synoptique:
#
# Pour chaque module sauf role et profile
# * créer le subtree
# * créer le repo bare
# * pousser les commit du subtree dans le dépot bare
#
# TODO:
# * Traduire la notice en anglais.
# * Traiter le cas où remote_prefix n'est pas local.
#


#============================================================================
# VARS
#============================================================================

PGM=${PGM:-$(basename $0)}
# Variables
RESTORE='\033[0m'
RED='\033[00;31m'
GREEN='\033[00;32m'

#============================================================================
# FUNCTIONS
#============================================================================
usage () {
   cat <<EOF_USAGE

Usage: ${PGM} <remote_prefix> <remote_module_prefix> <module_dir>
  
     
EOF_USAGE
}

banner () {
  tput clear
  cat <<EOF_BRUCE


PUPPET module splitter



EOF_BRUCE
}


error () {
	echo -e "${RED}[-] ${*}${RESTORE}"
}
warning () {
	echo -e "${RED}[!]${RESTORE} ${*}"
}

action () {
	echo -e "${GREEN}[*] ${*}${RESTORE}"
}

info() {
   printf -- "[*] ${*}"
}


check_cmd() {

   if [ -x "${2}" ]
   then
     info " cmd ${2} ok\n"
   else
     error " cmd ${1} not found..."
     CHECK_ERROR=$(( CHECK_ERROR + 1 ))
   fi
}


#============================================================================
# MAIN
#============================================================================

banner

if [ $# != 3 ]
then
	usage
	exit 1
fi


REMOTE_PREFIX="${1}"
MODULE_PREFIX="${2}"
MODULES_DIR="${3}"



info "Vérification des pré-requis\n"
action "Vérification du répertoire remote (${REMOTE_PREFIX})"
if [ ! -d "${REMOTE_PREFIX}" ]
then
	error "Répertoire inexistant...  On quitte ..."
	exit 1
fi
action "Vérification du répertoire des modules (${MODULES_DIR})"
if [ ! -d "${MODULES_DIR}" ]
then
	error "Répertoire inexistant...  On quitte ..."
	exit 1
fi

cd $MODULES_DIR
git_top_level=$(git rev-parse --show-toplevel)
cd ${git_top_level}
rel_git_top_level="${git_top_level//*\/}"
rel_module_dir=${MODULES_DIR//*${rel_git_top_level}\/}

split_tag="split-$(date +%Y%m%d)"

info "Traitement des modules\n\n"
info "Prefix module : ${MODULE_PREFIX}\n"
info "Tag du split  : ${split_tag}\n"
info "Remote        : ${REMOTE_PREFIX}\n"
info "Source        : ${git_top_level}/${rel_module_dir}\n\n"



for m in $(ls ${rel_module_dir})
do
	remote_repo="${REMOTE_PREFIX}/${MODULE_PREFIX}$m.git"
 	info "\nTraitement du module $m\n\n"

	if [ -d ${rel_module_dir}/${m}/.git ]
	then
		warning "déja externalisé"
		continue
	fi


	action "Split et création de la branch $m"
    git subtree split -P ${rel_module_dir}/${m} -b ${m}
	action "Création du dépot distant"
	if [ -d ${remote_repo} ]
	then
		warning "${remote_repo} existe déjà"
		continue
	fi
	git init --bare "${remote_repo}"

	action "Ajout du tag"
	git tag -f ${split_tag} $m

	action "Push vers le dépôt distant"
	git remote add $m ${remote_repo}
	git push --follow-tags $m $m:master

	git remote remove $m

done

