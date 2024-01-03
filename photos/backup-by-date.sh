#!/usr/bin/bash
#
#

set -o pipefail
set -o nounset
set -o errexit

action () {
    printf -- "[+] %s\n"  "${@}"
}

info () {
    printf -- "[*] %s\n"  "${@}"
}

error () {
    printf -- "[-] %s\n"  "${@}"
}

warning () {
    printf -- "[!] %s\n"  "${@}"
}

exit_on_error () {
    error "$@"
    exit 1
}



BACKUPDIR="${BACKUPDIR:-/srv/nextcloud/data/francois/files/Photos}"
SOURCEDIR="${SOURCEDIR:-$(realpath .)}"




action "Backup $SOURCEDIR to $BACKUPDIR/YYYY/MM"

[ -d "$BACKUPDIR" ] || {
    error "Backup dir not found ( $BACKUPDIR )"
    exit 1
}

pushd "$SOURCEDIR" >/dev/null || {
	error "Can't access $SOURCEDIR"
    exit 1
}


find . -type f | while read f
do
	when="$( exiftool -MediaCreateDate  -d "%Y/%m" -DateTimeOriginal -s -S "$f")"
	[ -n "$when" ] || {
		info "$f : no date found ($(file "$f"))"
	    continue
	}
	destdir="$BACKUPDIR/$when"

	[ -d "$destdir" ] || {
		mkdir -p "$destdir" \
		&& info "$destdir created" \
		|| error "Can't create $destdir"
	}
	[ -f "$destdir/$f" ] || {
	    cp -a "$f" "$destdir/$f"  \
		&& info "Copy $f to $destdir/$f" \
	    || error "Copying $f to $destdir/$f"
	}
done

