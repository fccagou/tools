#!/usr/bin/bash
#

set -ue
set -o pipefail


build () {
  local builddir

  builddir="${1-build}"


  # On build rootlesskit utilisé par les shells
  # TODO: regarder plus précisément
  [ -d "$builddir"/rootlesskit ] \
	  || git clone https://github.com/rootless-containers/rootlesskit.git "$builddir"/rootlesskit

  ## On build les binaires si besoin
  [ -f "$builddir"/rootlesskit/bin/rootlessctl ] \
    && [ -f "$builddir"/rootlesskit/bin/rootlesskit ] \
    && [ -f "$builddir"/rootlesskit/bin/rootlesskit-docker-proxy ] \
      || {
        set -e
        cd "$builddir"/rootlesskit
        pwd
        make -j3
        cd -
    }
    printf -- "[*] using %s \n" "$(pwd)"
    ls -altr "$builddir"/rootlesskit/bin/*


}

rootless_install () {

  local rootlessdir

  local bindir
  local builddir

  rootlessdir="${1:-docker-rootless}"
  bindir="$rootlessdir"/bin
  builddir="${2-build}"

  # On crée un environnement local
  [ -d "$bindir" ] || mkdir -p "$bindir"

  # On récupère les binaires qu'on vient de construire
  cp "$builddir"/rootlesskit/bin/rootless* "$bindir"/

  # On récupère les shells si nécessaire
  for f in dockerd-rootless-setuptool.sh dockerd-rootless.sh
  do
    [ -f "$f" ] || curl --silent -o "$bindir"/"$f"  https://raw.githubusercontent.com/moby/moby/master/contrib/"$f"
    chmod +x "$bindir"/"$f"
  done

  # Les shells s'attendent )à ce que docker soit dans le même répertoire.
  [ -f "$bindir"/docker ] || [ -f /usr/bin/docker ] && ln -sf /usr/bin/docker "$bindir"

  # Pour le suivi
  sha256sum "$bindir"/{dockerd-rootless-setuptool.sh,dockerd-rootless.sh,rootlessctl,rootlesskit,rootlesskit-docker-proxy} > "$rootlessdir"/sha256sum.txt

}

archive () {
	local prefix
	local archivename

	prefix="$1"
	archivename="$2"
}


# On met à jour le path avec tous les binaires nécessaires.
# TODO: garder les sources et mettre les binaires dans un seul endroit
#
#
set +u
BUILDDIR="${BUILDDIR:-build}"
ROOTLESSDIR="${ROOTLESSDIR:-"$BUILDDIR"/docker-rootless}"
set -u


[ "$#" == 0 ] && cmd="no-command-set (install|uninstall|build)" || cmd="$1"

case "$cmd" in

    "install")
        bash "$0" build "$BUILDDIR"
        rootless_install "$ROOTLESSDIR" "$BUILDDIR"
        export PATH="$(realpath "$ROOTLESSDIR")"/bin:"$PATH"
        bash "$ROOTLESSDIR"/bin/dockerd-rootless-setuptool.sh install 2>&1 | tee "$0"-install-"$(date +%s)".log
        ;;
    "uninstall")
        export PATH="$(realpath "$ROOTLESSDIR")"/bin:"$PATH"
        bash "$ROOTLESSDIR"/bin/dockerd-rootless-setuptool.sh uninstall 2>&1 | tee "$0"-uninstall-"$(date +%s)".log
        ;;
    "build")
        build "$BUILDDIR"
        ;;
     *)
         printf -- "[-] commande inconnue : %s\n" "$cmd"
         exit 1
        ;;
esac


