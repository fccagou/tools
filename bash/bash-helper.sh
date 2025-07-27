#!/usr/bin/bash
#
# vim: tabstop=4 shiftwidth=4 expandtab
#
# 2025 - fccagou <me@fccagou.fr>
#
# Template de shell script
#
## Informations shellcheck
# Liste des tests désactivés volontairement à certains endroits.
#
#  https://www.shellcheck.net/wiki/SC1090: ne pas suivre le check des fichiers sourcés
#  https://www.shellcheck.net/wiki/SC2001: utiliser bash expansion plutôt que echo xxx | sed ...
#  https://www.shellcheck.net/wiki/SC2034: variable non utilisée _(couleur ou truc en béta)_
#  https://www.shellcheck.net/wiki/SC2044: utiliser find exec plutôt que find | while
#  https://www.shellcheck.net/wiki/SC2046: utiliser des "" autour de variables.
#  https://www.shellcheck.net/wiki/SC2059: ne pas utiliser des variables dans printf.
#  https://www.shellcheck.net/wiki/SC2086: comme 2046
#  https://www.shellcheck.net/wiki/SC2181: préférer if ! macommand à macommand; if [ $? == 0 ]
#  https://www.shellcheck.net/wiki/SC2206: comme 2046
#  https://www.shellcheck.net/wiki/SC2207: préférer l'usage de mapfile

set -euo pipefail

# TODO: transformer en wrapper pour que le code ne soit pas modofié par le user
#       Pour ça, il faut ajouter un source du code au bon endroit pour charger tout le code utilisateur
#
GIT=/usr/bin/git
PGM=${PGM:-$(basename "$0")}

[ "$TERM" = "screen" ] && TERM=xterm-256color

# Variables
# shellcheck disable=SC2034
if tput setaf 1 &> /dev/null; then
    tput sgr0 &>/dev/null ; # reset colors
    bold=$(tput bold);
    reset=$(tput sgr0);
    # Solarized colors, taken from http://git.io/solarized-colors.
    black=$(tput setaf 0);
    blue=$(tput setaf 33);
    cyan=$(tput setaf 37);
    green=$(tput setaf 64);
    orange=$(tput setaf 166);
    purple=$(tput setaf 125);
    red=$(tput setaf 124);
    violet=$(tput setaf 61);
    white=$(tput setaf 15);
    yellow=$(tput setaf 136);
    grey=$(tput setaf 230);
else
    bold="";
    reset="\\e[0m";
    black="\\e[1;30m";
    blue="\\e[1;34m";
    cyan="\\e[1;36m";
    green="\\e[1;32m";
    orange="\\e[1;33m";
    purple="\\e[1;35m";
    red="\\e[1;31m";
    violet="\\e[1;35m";
    white="\\e[1;37m";
    yellow="\\e[1;33m";
    grey="${white}"
fi;

RESTORE='\e[0m'
RED='\e[31m'
GREEN='\e[38;5;64m'
# shellcheck disable=SC2034
YELLOW='\e[33m'
BLUE='\e[34m'

COLOR_CHAPTER='\e[33;48;5;52m['
COLOR_TITLE1='\e[7;49;37m['
COLOR_ERROR=${RED}
COLOR_INFO=${BLUE}
COLOR_ACTION=${GREEN}
COLOR_WARNING=${YELLOW}
COLOR_TODO=${BLUE}

COLOR_COMPAT="${orange}"
COLOR_3DOT="${blue}"


# ===================================================================================================
#  Gestion des erreurs + aide
# ===================================================================================================

chapter  () {
    printf -- "${COLOR_CHAPTER}% 100s\r[#] %s${RESTORE}\n" " " "${*}"
}

title1  () {
    printf -- "${COLOR_TITLE1}% 100s\r |  %s${RESTORE}\n" " " "${*}"
}


error () {
    printf -- "${COLOR_ERROR}[-] %s${RESTORE} \n" "${*}"
}

warning () {
    printf -- "${COLOR_WARNING}[!] %s${RESTORE}\n" "${*}"
}

action () {
    printf -- "${COLOR_ACTION}[+] %s${RESTORE}\n" "${*}"
}


info () {
    printf -- "${COLOR_INFO} |->${RESTORE} %s\n" "${*}"
}

todo () {
    printf -- "${COLOR_TODO}[ ] TODO: %s${RESTORE}\n" "${*}"
}


safe_pushd() {
    local dirname
    dirname="$1"

    if ! pushd "$dirname" > /dev/null
    then
        error "Impossible de changer de dossier ($dirname)"
        info "Vérifier les droits ou la présense du dossier"
        info "Dossier courant: $(pwd)"
        exit 1
    fi
}

safe_popd() {
    if ! popd >/dev/null
    then
        error "Impossible de changer de dossier."
        info "Vérifier les droits ou la présense du dossier."
        exit 1
    fi
}

_check_boolean() {
    case "$1" in
        "true"|"1"|"yes")
            printf -- "1"
            return 0
            ;;
        "false"|"0"|"no")
            printf -- "0"
            return 1
            ;;
        help)
            info "Les valeurs possible sont:"
            info "   1,true,yes"
            info "   0,false,no"
            ;;
        *)
            printf -- ""
            return 1
            ;;
    esac
}


__function_exists () {
    declare -F "$1" >/dev/null
}

# -------------------------------
#  progress bar
# -------------------------------
_PB_NB=0

__show_progress () {
    if [ "${PB_NB}" == "${COLUMS}" ]
    then
        _PB_NB=0
        printf -- "\n"
    else
        PB_NB=$(( PB_NB + 1 ))
    fi
    printf -- "."
}

# ===================================================================================================
#  Gestion de l'authentification
# ===================================================================================================
_AUTH_INIT_ () {

    if /usr/bin/test -z "${USERLOGIN}"
    then
        error "Vous n'etes pas identifie !"
        exit 3
    fi
    if [ -z "${AUTH_TYPE}" ] || [ "${AUTH_TYPE}" = 'kerberos' ] ; then
        trap _AUTH_CLEAR_ EXIT
        [ -n "${GIT_PRINCIPAL}" ] \
            && PRINC="${GIT_PRINCIPAL}" \
            || PRINC="${USERLOGIN}"

        if [ "${PRINC%/*}" = "host" ]
        then
            USEKEYTAB="-k"
            USERLOGIN=${PRINC#*/}
        else
            USEKEYTAB=""
        fi
        CACHE="/dev/shm/krb5cache_${USERLOGIN}"

        if [ "${BATCH}" = "yes" ]; then
            ${KINIT} ${USEKEYTAB} -R -c "${CACHE}" >/dev/null 2>&1
        else
            false
        fi

        # shellcheck disable=SC2181
        [ "$?" == "0" ] \
            || ${KINIT} ${USEKEYTAB} -F -c "${CACHE}" -p "${PRINC}" \
            || ${KINIT} ${USEKEYTAB} -F -c "${CACHE}" -p "${PRINC}" \
            || ${KINIT} ${USEKEYTAB} -F -c "${CACHE}" -p "${PRINC}" \
            || { ${ECHO} "Le 'kinit' a echoue... "; exit 1; }

        if [ -f "${CACHE}" ]; then
            export KRB5CCNAME="FILE:${CACHE}"
        else
            error "Probleme: il n'y a pas de ticket!"
            exit 3
        fi
    fi
}


_AUTH_CLEAR_ () {
    if [ -z "${AUTH_TYPE}" ] || [ "${AUTH_TYPE}" = 'kerberos' ] ; then
        action "Nettoyage..."
        /usr/bin/kdestroy
        USERLOGIN=${PRINC#*/}
        /bin/rm -f /dev/shm/krb5cache_"${USERLOGIN}"
    fi
}

# =============================================================================
#  USAGE & HELP
# =============================================================================
#
__usage () {
    if __function_exists usage; then
        usage
        printf -- "\n"
        printf -- "Commandes du wrapper:\n"
        printf -- "  help             Aide détaillées\n"
        printf -- "  options          Liste des options générales\n"
        printf -- "  completion       Comment mettre en place la completion\n"
    else
       # Default usage
       cat <<EOF_usage_template
$PGM facilite la création de shell bash dynamique

     $PGM implémente la partie récurrente des shell

     - gestion des options
     - gestion de l'aide
     - completion

     et permet d'étendre les fonctionnalités.

     Le mode opératoire est simple,

     1. générer un shell avec la commande wrap (cf $PGM help wrap)
     2. Ajouter l'implémentation de commande à votre script:
       - écrire la fonction "command_votre_commande"
       - écrire la fonction "help_cmd_votre_commande" (cf: "$PGM help votre_commande")
       - écrire la fonction "complete_cmd_votre_commande

     Pour commencer:
       # Générer un shell
       $PGM wrap > monshell.sh
       # changer les droits
       chmod +x monshell.sh
       # Mettre en place la completion
       source <(monshell.sh completion bash)
       # Tester
       ./monshell.sh
       # Ensuite éditez le code pour ajouters vos commandes

Commandes:
  wrap             Comment ecrire le code qui sera étendu par ce wrapper
  help             Aide détaillées
  options          Liste des options générales
  completion       Comment mettre en place la completion

Usage:
    \$PGM [commande] [options]

Utiliser "\$PGM help <commande>" pour plus d'information sur la commande
EOF_usage_template
    fi
}


__help_commande () {
    local helpfct=help_cmd_"$1"
    if __function_exists __"${helpfct}"; then
        __"$helpfct"
        printf -- '\nUtiliser "%s options" pour connaître les options globales\n' "$PGM"
    elif __function_exists "${helpfct}"; then
        "$helpfct"
        printf -- '\nUtiliser "%s options" pour connaître les options globales\n' "$PGM"
    else
        warning "Pas d'aide détaillée pour $1"
        help_cmd_help "$1"
    fi
}





help_cmd_completion () {
    cat <<EOF_HELP_completion
Affiche le code de completion pour bash.

 Pour fonctionner, le code de completion doit être chargé dans votre environnement.
 Lire les exemples ci-dessous pour sa mise en oeuvre.

 Le mécanisme de completion est automatisé à partir du contenu affiché par la fonction usage()
 Pour ajouter une completion particulière à une commande, il faut ajouter la fonction
 "complete_cmd_votre_commande" dans votre code en prenant exemple sur les fonctions existantes.


Exemples:
  # Installer bash completion sur macOS avec homebrew
  ## avec Bash 3.2 inclus dans macOS
  brew install bash-completion
  ## ou avec Bash 4.1+
  brew install bash-completion@2
  # Puis
  $PGM completion bash > \$(brew --prefix)/etc/bash_completion.d/kubectl


  # Installer bash completion sur Linux
  ## Installer le paquet bash-completion si nécessaire via le gestionnaire de paquets.
  ## Charger la completion bash de $PGM dans le shell courant
  source <($PGM completion bash)
  ## Pour une activation automatique dans le shell, écrire le code dans un fichier
  ## et le charger depuis .bash_profile
  $PGM completion bash > ~/.${PGM}_completion
  printf -- "# $PGM shell completion\nsource '$HOME/.${PGM}_completion'" >> $HOME/.bash_profile
  source $HOME/.bash_profile

Options:
    --alias-only=false|[true]:
        Ne renvoie pas tout le code mais juste l'association avec la commande

Usage:
  $PGM completion SHELL [options]

  SHELL: bash
EOF_HELP_completion
}

help_cmd_help () {
    local command
    (( $# == 0 )) && command="_exemple_" || command="$1"

    cat <<EOF_HELP_usage
Voici comment ajouter l'aide en ligne pour la commande $command

Dans votre code, créer la fonction "help_cmd_$command" qui affiche l'aide
en respectant la présentation suivante.

Elle sera accessible en utilisant "$PGM help $command"

# ---8<-----------------------------------------------------------------------
help_cmd_$command () {
    cat <<EOF_HELP_$command
Description sommaire de la commande "$command"

 Description générale décalée d'un seul caractère
 sur plusieurs lignes si nécessaire.

Exemples:
  # Descrition exemple 1
  \$PGM $command exemple 1
  # Descrition exemple 2
  \$PGM $command exemple 2 --opt1=value1

Options;
    --opt1:
        Description option 1
    --opt2:
        Description option 2

Usage:
  \$PGM $command [flags] [options]
EOF_HELP_$command
}
# -------------------------------------------------------------------->8------
EOF_HELP_usage
}

__help_cmd_options() {
    cat <<EOF_OPTIONS
Les options suivantes peuvent être passées à toutes les commandes

    --conf=conf_file:
        Non du fichier de configuration

    -v, --verbose=true|false:
        Affiche plus de détail dans les commandes

EOF_OPTIONS

    if __function_exists help_cmd_options; then
        help_cmd_options
    fi
}




help_cmd_wrap () {
    cat <<EOF_HELP_wrap
Génère le squelette du code wrappé

Exemples:
  # Générer le code
  $PGM wrap > monshell.sh
  # changer les droits
  chmod +x monshell.sh
  # Mettre en place la completion
  source <(./monshell.sh completion bash)
  # Tester
  ./monshell.sh
  # Ensuite éditez le code pour ajouters vos commandes

Usage:
  $PGM wrap [flags] [options]
EOF_HELP_wrap
}


command_wrap () {

    cat <<EOF_wrap
#!/usr/bin/bash
#
# vim: tabstop=4 shiftwidth=4 expandtab
#
# ****************************************************************************************************
#   Usage
# ****************************************************************************************************
#
usage () {
    cat <<EOF_usage
\$PGM: Sur la première ligne écrire le résumé de l'usage du programme

 Mettre ici la description et les explications plus détaillées du programme.
 Ne laisser qu'un seul caractère en début de chaque ligne de la description.

Groupe de commandes 1:
  commande_x        Résumé de la commande 1
  commande_y        Ce texte sera utilisé dans l'aide en ligne
  commande_z        Et dans la completion

Usage:
    \$PGM [commande] [options]

Utiliser "\$PGM help <commande>" pour plus d'information sur la commande
EOF_usage
}

# ****************************************************************************************************
#
#     Variables du programme
#
#     Pour chaque variable, ecrire un commentaire sous la forme
#
#        # @nomdevariable: description
#
#     Pour mieux identifier la portée des variables respecter le formalisme suivant:
#
#     - portée globale, en majuscule
#
#        _VAR_EN_MAJUSCULE="une variable globale non valorisable dans l'env utiisateur"
#        VAR_EN_MAJUSCULE="\${VAR_EN_MAJUSCULE:-"valeur par défaut pouvant être valorisée dans l'env"}"
#
#     - portée locale, en minuscule
#
#        var_en_minuscule="valeur initiale"
#        _var_en_minuscule="Valeur par défaut"
#
# ****************************************************************************************************



# ****************************************************************************************************
#
#     Implémentation du code des commandes supplémentaires.
#
#     Pour chaque nouvelle commande, créer respectivement les fonctions
#     - command_nouvelle_commande()      : implementation du code
#     - help_cmd_nouvelle_commande()     : pour l'aide en ligne (exmple \$0 help help
#     - complete_cmd_nouvelle_commande() : pour traiter une completion particulière
#
#     et ajouter une entrée dans le code de la fonction usage()
#
# ****************************************************************************************************

help_cmd_options () {
    # Surcharge des options globales par défaut
    :
}

# ****************************************************************************************************
# MAIN
# ****************************************************************************************************
# shellcheck disable=SC1091
source "$(readlink -f "$PGM")"
EOF_wrap

}

# ------------------------------------------------------------------------------
#  COMPLETION
# ------------------------------------------------------------------------------

_COMPLETION_DEFAULT=0
_COMPLETION_ERROR=1

__complete() {
    local shellCompDirectiveDefault=$_COMPLETION_DEFAULT
    local shellCompDirectiveError=$_COMPLETION_ERROR
    local shellCompDirectiveNoSpace=2
    local shellCompDirectiveNoFileComp=4
    local shellCompDirectiveFilterFileExt=8
    local shellCompDirectiveFilterDirs=16
    local shellCompDirectiveKeepOrder=32

    local shellCompDirective=$shellCompDirectiveNoFileComp

    if (( $# == 0 )); then
        error "il faut au minimum un paramètre, reçu 0"
        exit 1
    fi


    # Plusieurs paramètres, on doit trouver la commande pour déterminer
    # la completion à réaliser avec le dernier paramètre.
    local command=""
    local lastparam="${@: -1}"

    local options=()
    local args=()
    local p
    local o

    for p in "$@"; do
        case "$p" in
            -*)
                options+=("$p")
                ;;
            *)
                args+=("$p")
                ;;
        esac
    done

    if (( ${#args[*]} > 0 )); then
        command="${args[0]}"
    fi

    local shellCompDirective=$shellCompDirectiveNoFileComp

    if [[ "$lastparam" == -*=* ]]; then
        # On est dans le cas d'une option et on attend une valeur
        printf -- ':%d\n' $shellCompDirective
        return 0

    elif [[ "$lastparam" == -* ]]; then
        # On est dans le cas d'une option non encore complete
        local o="${lastparam//=*}"
        local v="${lastparam//*=}"

        shellCompDirective=$shellCompDirectiveNoSpace
        __complete_global_options | grep -- "^${o}" || :
        if [ -n "$command" ]; then
            __complete_commande_options "$command"
            printf -- ':%d\n' $shellCompDirective
            return 0
        fi
    fi

    if [ -z "$command" ]; then
        # La commande n'est pas définie
        __complete_commandes_descriptions

    elif (( ${#args[*]} == 1 )) && [ "$lastparam" == "$command" ]; then
        # Completion de la commande en cours
        if __command_exists "${command}"; then
            # C'est bien une commande existante, on fini la completion
            printf -- "%s\n" "$command"
        else
            # La commande n'est complètement définie, on envoie les options possibles
            __complete_commandes_descriptions "${command}"
        fi

    elif __function_exists complete_cmd_"$command"; then
        # Completion de la commande ok, on traite la completion par commande
        complete_cmd_"$command" "$lastparam" "${args[*]:1}"
    else
        __complete_fallback "$command" "$lastparam" "${args[*]:1}"
        shellCompDirective="$?"
    fi
    printf -- ':%d\n' $shellCompDirective
}

__complete_fallback () {
    if __function_exists complete_fallback; then
        complete_fallback "${@}"
    else
        # Pas de completion
        return $_COMPLETION_ERROR
    fi
}


__command_exists () {
    __liste_des_commandes | grep -q "^${1}$"
}

__command_run () {
    local c
    c="$1"
    if __function_exists command_"$c"; then
        shift
        command_"$c" "$@"
    else
        error "Commande non implémentée: $c"
        info "Ecrire la fonction 'command_$c' dans '$PGM'"
        return 1
    fi
}

__liste_des_commandes () {
    local filter
    if (( $# == 0 )) || [ -z "$1" ];  then
        filter="[a-z]"
    else
        filter="$1"
    fi

    __usage \
        | grep -E "^  ${filter}"\
        | sed 's/^  \([^ ]*\).*/\1/'
}

__complete_commandes_descriptions () {
    local filter
    if (( $# == 0 )) || [ -z "$1" ];  then
        filter="[a-z]"
    else
        filter="$1"
    fi

    __usage \
        | grep -E "^  ${filter}"\
        | sed 's/^  \([^ ]*\) */\1\t/' \
        | grep -vE "^${PGM}|PGM"
}

__complete_global_options () {
    __help_cmd_options \
        | grep -- '^    -[^:]*:' \
        | tr ',' '\n' \
        | sed 's/^ *\([^:=]*\).*$/\1=\t\n/'
}


__complete_commande_options() {
    local command
    (( $# == 0 )) && command="" || command="$1"

    help_cmd_"${command}" \
        | grep -E -- '^    -[^:]*:' \
        | tr ',' '\n' \
        | sed 's/^ *\([^:=]*\).*$/\1=/'
}

# =============================================================================
#  COMMANDES par défaut
# =============================================================================

complete_cmd_help () {
    local lastparam
    local args

    lastparam="$1"
    shift;
    args=("${@}")

    if (( ${#args[*]} == 0 )) ; then
        __complete_commandes_descriptions
    else
        local verb
        verb="${args[*]:0}"

        if __command_exists "$verb"; then
            __help_commande "$verb"
        else
            __complete_commandes_descriptions "$verb"
        fi
    fi
}

# Exemples pour le template
command_commande1 () {
    echo "Commande 1"
}

command_commande2 () {
    echo "Commande 2"
}

complete_cmd_subverbs () {

    local lastparam
    local args

    lastparam="$1"
    shift;
    args=("${@}")

    if (( ${#args[*]} == 0 )); then
        printf -- "verb1\tdescription verb1\n"
        printf -- "verb2\tdescription verb2\n"
    else
        local verb
        verb="${args[*]:0}"

        if [ "$verb" == "verb1" ] || [ "$verb" == "verb2" ]; then
            __complete_fallback "subverbs" "$lastparam" "${args[*]:1}"
        elif [[ "verb1" == "${args[*]:0}"* ]]; then
            printf -- "verb1\n"
        elif [[ "verb2" == "${args[*]:0}"* ]]; then
            printf -- "verb2\n"
        else
            return 1
        fi
    fi

}


command_completion () {
    local alias_only
    alias_only=false

    while (( $# != 0 )); do
        case "$1" in
            --alias-only=*)
                alias_only="${1//*=}"
                if ! _check_boolean "${alias_only}"; then
                    erreur "alias_only: valeur booleen attendue"
                    info "$(_check_boolean help)"
                    exit 1
                fi
                ;;
        *)
            error "Parametre inconnu: $1"
            exit 1
            ;;
        esac
        shift
    done

    if [ "${alias_only}" == "0" ]; then
    cat <<'EOF_COMPLETION'
#
# Copyright 2016 The kubernetesnetes Authors.
#           2025 Francois CHENAIS <me@fccagou.fr>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# bash completion V2 for commonshell
#
# * 2025: FC, replace kubectl by commonshell and declare only once the functions
#
#                              -*- shell-script -*-



# In case of multiple shell using this completion, only declare function once
if ! declare -F __commonshell_debug >/dev/null; then

__commonshell_debug()
{
    if [[ -n ${BASH_COMP_DEBUG_FILE-} ]]; then
        echo "$*" >> "${BASH_COMP_DEBUG_FILE}"
    fi
}

# Macs have bash3 for which the bash-completion package doesn't include
# _init_completion. This is a minimal version of that function.
__commonshell_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref "$@" cur prev words cword
}

# This function calls the commonshell program to obtain the completion
# results and the directive.  It fills the 'out' and 'directive' vars.
__commonshell_get_completion_results() {
    local requestComp lastParam lastChar args

    # Prepare the command to request completions for the program.
    # Calling ${words[0]} instead of directly commonshell allows handling aliases
    args=("${words[@]:1}")
    requestComp="${words[0]} __complete ${args[*]}"

    lastParam=${words[$((${#words[@]}-1))]}
    lastChar=${lastParam:$((${#lastParam}-1)):1}
    __commonshell_debug "lastParam ${lastParam}, lastChar ${lastChar}"

    if [[ -z ${cur} && ${lastChar} != = ]]; then
        # If the last parameter is complete (there is a space following it)
        # We add an extra empty parameter so we can indicate this to the go method.
        __commonshell_debug "Adding extra empty parameter"
        requestComp="${requestComp} ''"
    fi

    # When completing a flag with an = (e.g., commonshell -n=<TAB>)
    # bash focuses on the part after the =, so we need to remove
    # the flag part from $cur
    if [[ ${cur} == -*=* ]]; then
        cur="${cur#*=}"
    fi

    __commonshell_debug "Calling ${requestComp}"
    # Use eval to handle any environment variables and such
    out=$(eval "${requestComp}" 2>/dev/null)

    # Extract the directive integer at the very end of the output following a colon (:)
    directive=${out##*:}
    # Remove the directive
    out=${out%:*}
    if [[ ${directive} == "${out}" ]]; then
        # There is not directive specified
        directive=0
    fi
    __commonshell_debug "The completion directive is: ${directive}"
    __commonshell_debug "The completions are: ${out}"
}

__commonshell_process_completion_results() {
    local shellCompDirectiveError=1
    local shellCompDirectiveNoSpace=2
    local shellCompDirectiveNoFileComp=4
    local shellCompDirectiveFilterFileExt=8
    local shellCompDirectiveFilterDirs=16
    local shellCompDirectiveKeepOrder=32

    if (((directive & shellCompDirectiveError) != 0)); then
        # Error code.  No completion.
        __commonshell_debug "Received error from custom completion go code"
        return
    else
        if (((directive & shellCompDirectiveNoSpace) != 0)); then
            if [[ $(type -t compopt) == builtin ]]; then
                __commonshell_debug "Activating no space"
                compopt -o nospace
            else
                __commonshell_debug "No space directive not supported in this version of bash"
            fi
        fi
        if (((directive & shellCompDirectiveKeepOrder) != 0)); then
            if [[ $(type -t compopt) == builtin ]]; then
                # no sort isn't supported for bash less than < 4.4
                if [[ ${BASH_VERSINFO[0]} -lt 4 || ( ${BASH_VERSINFO[0]} -eq 4 && ${BASH_VERSINFO[1]} -lt 4 ) ]]; then
                    __commonshell_debug "No sort directive not supported in this version of bash"
                else
                    __commonshell_debug "Activating keep order"
                    compopt -o nosort
                fi
            else
                __commonshell_debug "No sort directive not supported in this version of bash"
            fi
        fi
        if (((directive & shellCompDirectiveNoFileComp) != 0)); then
            if [[ $(type -t compopt) == builtin ]]; then
                __commonshell_debug "Activating no file completion"
                compopt +o default
            else
                __commonshell_debug "No file completion directive not supported in this version of bash"
            fi
        fi
    fi

    # Separate activeHelp from normal completions
    local completions=()
    local activeHelp=()
    __commonshell_extract_activeHelp

    if (((directive & shellCompDirectiveFilterFileExt) != 0)); then
        # File extension filtering
        local fullFilter filter filteringCmd

        # Do not use quotes around the $completions variable or else newline
        # characters will be kept.
        for filter in ${completions[*]}; do
            fullFilter+="$filter|"
        done

        filteringCmd="_filedir $fullFilter"
        __commonshell_debug "File filtering command: $filteringCmd"
        $filteringCmd
    elif (((directive & shellCompDirectiveFilterDirs) != 0)); then
        # File completion for directories only

        local subdir
        subdir=${completions[0]}
        if [[ -n $subdir ]]; then
            __commonshell_debug "Listing directories in $subdir"
            pushd "$subdir" >/dev/null 2>&1 && _filedir -d && popd >/dev/null 2>&1 || return
        else
            __commonshell_debug "Listing directories in ."
            _filedir -d
        fi
    else
        __commonshell_handle_completion_types
    fi

    __commonshell_handle_special_char "$cur" :
    __commonshell_handle_special_char "$cur" =

    # Print the activeHelp statements before we finish
    if ((${#activeHelp[*]} != 0)); then
        printf "\n";
        printf "%s\n" "${activeHelp[@]}"
        printf "\n"

        # The prompt format is only available from bash 4.4.
        # We test if it is available before using it.
        if (x=${PS1@P}) 2> /dev/null; then
            printf "%s" "${PS1@P}${COMP_LINE[@]}"
        else
            # Can't print the prompt.  Just print the
            # text the user had typed, it is workable enough.
            printf "%s" "${COMP_LINE[@]}"
        fi
    fi
}

# Separate activeHelp lines from real completions.
# Fills the $activeHelp and $completions arrays.
__commonshell_extract_activeHelp() {
    local activeHelpMarker="_activeHelp_ "
    local endIndex=${#activeHelpMarker}

    while IFS='' read -r comp; do
        if [[ ${comp:0:endIndex} == $activeHelpMarker ]]; then
            comp=${comp:endIndex}
            __commonshell_debug "ActiveHelp found: $comp"
            if [[ -n $comp ]]; then
                activeHelp+=("$comp")
            fi
        else
            # Not an activeHelp line but a normal completion
            completions+=("$comp")
        fi
    done <<<"${out}"
}

__commonshell_handle_completion_types() {
    __commonshell_debug "__kubectl_handle_completion_types: COMP_TYPE is $COMP_TYPE"

    case $COMP_TYPE in
    37|42)
        # Type: menu-complete/menu-complete-backward and insert-completions
        # If the user requested inserting one completion at a time, or all
        # completions at once on the command-line we must remove the descriptions.
        # https://github.com/spf13/cobra/issues/1508
        local tab=$'\t' comp
        while IFS='' read -r comp; do
            [[ -z $comp ]] && continue
            # Strip any description
            comp=${comp%%$tab*}
            # Only consider the completions that match
            if [[ $comp == "$cur"* ]]; then
                COMPREPLY+=("$comp")
            fi
        done < <(printf "%s\n" "${completions[@]}")
        ;;

    *)
        # Type: complete (normal completion)
        __commonshell_handle_standard_completion_case
        ;;
    esac
}

__commonshell_handle_standard_completion_case() {
    local tab=$'\t' comp
    # Short circuit to optimize if we don't have descriptions
    if [[ "${completions[*]}" != *$tab* ]]; then
        IFS=$'\n' read -ra COMPREPLY -d '' < <(compgen -W "${completions[*]}" -- "$cur")
        return 0
    fi

    __commonshell_debug "DEBUG 1"
    local longest=0
    local compline
    # Look for the longest completion so that we can format things nicely
    while IFS='' read -r compline; do
        [[ -z $compline ]] && continue
        # Strip any description before checking the length
        comp=${compline%%$tab*}
        __commonshell_debug "comp=${comp}"
        # Only consider the completions that match
        [[ $comp == "$cur"* ]] || continue
        COMPREPLY+=("$compline")
        if ((${#comp}>longest)); then
            longest=${#comp}
        fi
    done < <(printf "%s\n" "${completions[@]}")

    # If there is a single completion left, remove the description text
    if ((${#COMPREPLY[*]} == 1)); then
        __commonshell_debug "COMPREPLY[0]: ${COMPREPLY[0]}"
        comp="${COMPREPLY[0]%%$tab*}"
        __commonshell_debug "Removed description from single completion, which is now: ${comp}"
        COMPREPLY[0]=$comp
    else # Format the descriptions
        __commonshell_format_comp_descriptions $longest
    fi
}

__commonshell_handle_special_char()
{
    local comp="$1"
    local char=$2
    if [[ "$comp" == *${char}* && "$COMP_WORDBREAKS" == *${char}* ]]; then
        local word=${comp%"${comp##*${char}}"}
        local idx=${#COMPREPLY[*]}
        while ((--idx >= 0)); do
            COMPREPLY[idx]=${COMPREPLY[idx]#"$word"}
        done
    fi
}

__commonshell_format_comp_descriptions()
{
    local tab=$'\t'
    local comp desc maxdesclength
    local longest=$1

    local i ci
    for ci in ${!COMPREPLY[*]}; do
        comp=${COMPREPLY[ci]}
        # Properly format the description string which follows a tab character if there is one
        if [[ "$comp" == *$tab* ]]; then
            __commonshell_debug "Original comp: $comp"
            desc=${comp#*$tab}
            comp=${comp%%$tab*}

            # $COLUMNS stores the current shell width.
            # Remove an extra 4 because we add 2 spaces and 2 parentheses.
            maxdesclength=$(( COLUMNS - longest - 4 ))

            # Make sure we can fit a description of at least 8 characters
            # if we are to align the descriptions.
            if ((maxdesclength > 8)); then
                # Add the proper number of spaces to align the descriptions
                for ((i = ${#comp} ; i < longest ; i++)); do
                    comp+=" "
                done
            else
                # Don't pad the descriptions so we can fit more text after the completion
                maxdesclength=$(( COLUMNS - ${#comp} - 4 ))
            fi

            # If there is enough space for any description text,
            # truncate the descriptions that are too long for the shell width
            if ((maxdesclength > 0)); then
                if ((${#desc} > maxdesclength)); then
                    desc=${desc:0:$(( maxdesclength - 1 ))}
                    desc+="…"
                fi
                comp+="  ($desc)"
            fi
            COMPREPLY[ci]=$comp
            __commonshell_debug "Final comp: $comp"
        fi
    done
}

__start_commonshell()
{
    local cur prev words cword split

    COMPREPLY=()

    # Call _init_completion from the bash-completion package
    # to prepare the arguments properly
    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion -n =: || return
    else
        __commonshell_init_completion -n =: || return
    fi

    __commonshell_debug
    __commonshell_debug "========= starting completion logic =========="
    __commonshell_debug "cur is ${cur}, words[*] is ${words[*]}, #words[@] is ${#words[@]}, cword is $cword"

    # The user could have moved the cursor backwards on the command-line.
    # We need to trigger completion from the $cword location, so we need
    # to truncate the command-line ($words) up to the $cword location.
    words=("${words[@]:0:$cword+1}")
    __commonshell_debug "Truncated words[*]: ${words[*]},"

    local out directive
    __commonshell_get_completion_results
    __commonshell_process_completion_results
}

# -----------------------------------------------------------------------------------------------------------
# End of conditional declaration test at the top of the code
fi
EOF_COMPLETION

    fi # Fin de alias_only
    cat <<EOF_COMPLETE_CMD
if [[ \$(type -t compopt) = "builtin" ]]; then
    complete -o default -F __start_commonshell $PGM
else
    complete -o default -o nospace -F __start_commonshell $PGM
fi
EOF_COMPLETE_CMD
}

# ----------------------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------------------
__main () {
    # Lecture des options
    if [ $# == 0 ] ; then
        __usage
        exit 0
    fi

    ACTION="${1}"
    shift

    case "${ACTION}" in
        '__complete')
            __complete "$@"
            exit 0
            ;;
        'options')
            __help_cmd_options
            exit 0
            ;;
        '--help'|'-h')
            __usage
            exit 0
            ;;
        'help')
            if (( $# == 0 )); then
                __usage
                exit 0
            else
                if __command_exists "$1"; then
                    __help_commande "$1"
                else
                    error "Commande inconnue: $1"
                    __usage
                    exit 1
                fi
            fi
            ;;
        *)
            if __command_exists "$ACTION"; then
                __command_run "$ACTION" "$@"
            else
                error "Commande inexistante $ACTION"
                __usage
                exit 1
            fi
            ;;
    esac
}

# ------------------------------------------------------------------------------
#  VARIABLES INITIALISATION
# ------------------------------------------------------------------------------

global_conf_file="${global_conf_file:-/etc/"$PGM".conf}"
user_conf_file=""
# Mode verbeux.
verbose_env="${VERBOSE:-0}"
verbose_param=""

# Traite les options globales
while (( $# != 0 )) && [[ "$1" == -* ]]; do
    case "$1" in
        --verbose=*|-v=*)
            o="${1//*=}"
            if  _check_boolean "$o" >/dev/null; then
                verbose_param="$(_check_boolean "$o")"
            else
                error "l'option $1 doit avoir une valeur booléenne"
                __complete_global_options | grep "^${1//=*}"
                _check_boolean "help"
                exit 1
            fi
            ;;
        --verbose|-v)
            if (( $# > 1 )); then
                o="$2"
            else
                o=""
            fi

            if  _check_boolean "$o" >/dev/null; then
                verbose_param="$(_check_boolean "$o")"
            else
                error "l'option $1 doit avoir une valeur booléenne"
                __complete_global_options | grep "^${1//=*}"
                _check_boolean "help"
                exit 1
            fi
            ;;

        --conf=*)
            user_conf_file="${1//*=}"
            if [ -z "${user_conf_file}" ] || [ ! -f "${user_conf_file}" ]; then
                error "Fichier de configuration inconnu: '${user_conf_file}'"
                __complete_global_options | grep "^${1//=*}"
                exit 1
            fi
            ;;
        --conf)
            if (( $# > 1 )); then
                user_conf_file="$2"
            else
                user_conf_file=""
            fi

            if [ -z "${user_conf_file}" ] || [ ! -f "${user_conf_file}" ]; then
                error "Fichier de configuration inconnu: '${user_conf_file}'"
                __complete_global_options | grep "^${1//=*}"
                exit 1
            fi
            ;;
        *)
            if ! __function_exists "parse_options" || ! parse_options "$1" ; then
                error "Option inconnue: $1"
                __usage
                exit 1
            fi
            ;;
    esac
    shift
done

# TODO; utiliser ~/.config/ ou XDG_XXXX
#
user_conf_file="${user_conf_file:-"${HOME}"/."$PGM"}"

# Actuellement, le modèle (control-rep[https://github.com/puppetlabs/control-repo]
# ne peut être mise en place. Una alternative est de passer par un repo
# intermediaire controle-local
#

if /usr/bin/test -f "${global_conf_file}"
then
    # shellcheck disable=SC1090
    source "${global_conf_file}"
fi

if /usr/bin/test -f "${user_conf_file}"
then
    # shellcheck disable=SC1090
    source "${user_conf_file}"
fi


if [ -n "${verbose_param}" ]; then
    VERBOSE="${verbose_param}"
elif [ -n "$verbose_env" ]; then
    VERBOSE="${verbose_env}"
else
    VERBOSE="${VERBOSE:-0}"
fi

# --------------------------------
# implements: https://no-color.org/
# --------------------------------
# @NO_COLOR: désactive la couleur si valorisé
NO_COLOR="${NO_COLOR:-}"
# @CLICOLOR: 1=active la couleur du cli, 0 par défaut
# Implements: https://bixense.com/clicolors/
CLICOLOR="${CLICOLOR:-1}"
# @CLICOLOR_FORCE: 1=force la couleur, 0 par défaut
CLICOLOR_FORCE="${CLICOLOR_FORCE:-0}"

if [ -n "${NO_COLOR}" ] \
    || [ "${CLICOLOR}" == "0" ] \
    && tty -s \
    && [ "${CLICOLOR_FORCE}" == "0" ]
then
    COLOR_CHAPTER=""
    COLOR_TITLE1=""
    COLOR_ERROR=""
    COLOR_INFO=""
    COLOR_ACTION=""
    COLOR_WARNING=""
    COLOR_TODO=""
    RESTORE=""
fi




# ----------------------------------------------------------------------------------------
# Analyse des parametres
# ----------------------------------------------------------------------------------------
# Définir une fonction par paramètre

# ---8<---------------------------------------------------------
# Exemples par défaut qu'il est possible de supprimer.
#
check_param1 () {
    local param
    param="$1"

    [ -z "$param" ] && {
        error "param1 est vide"
        __usage
        exit 1
    }

    # On securise le nom de param1 en enlevant les caracteres problematiques
    # shellcheck disable=SC2001
    tmp="$(echo "$param" | sed -e 's/[^A-Za-z0-9_\-]/_/g')"

    [ "$param" = "$tmp" ] || {
        error "le nom du paramètre  ne doit contenir que des lettres (MAJ ou min), des chiffres ou les caracteres '_' et '-' "
        exit 1
    }
}
# -------------------------------------------------------->8----



# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# ADDONS END
# ====================================================================================================



# ===================================================================================================
#  MAIN
# ===================================================================================================
__main "$@"


