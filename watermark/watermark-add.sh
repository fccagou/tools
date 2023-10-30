#!/usr/bin/bash
#
#

set -o pipefail
set -o errexit
set -o nounset


action () {
	printf -- "[+] %s\n" "$@"
}

error () {
	printf -- "[-] %s\n" "$@"
}


usage () {
	cat <<EOF_USAGE

Usage: $0 [OPTIONS] <filename> <"watermark to add">

OPTIONS:

   --help|-h            : display this help

   --color color        : text color in #rgb format or color name (Default: ${color})
   --dest-dir dirname   : output prefix (Default: ${destdir})
   --to filename        : output filename (Default: ${destdir}/<filename>)
   --force              : force output overide (default: $force)

EOF_USAGE
}


# Defaults values
color=gray
destdir="."
from=""
watermark=""
force="no"


if [ -x /usr/bin/magick ]; then
	convert=/usr/bin/magick
elif [ -x /usr/bin/convert ]; then
	convert=/usr/bin/convert
else
	error "imagemagick not installed"
	exit 2
fi


# Check parameters
while [ "$#" -gt 0 ]
do
	case "$1" in
		--help|-h)
			usage
			exit 0
			;;
		--dest-dir)
			destdir="$2"
			shift
			;;
		--color)
			color="$2"
			shift
			;;
		--to)
			to="$2"
			shift
			;;
		--force)
			force=yes
			;;
		--*)
			error "Unknown parameter $1"
			usage
			exit 1
			;;
		*)
			if [ -z "$from" ]; then
				from="$1"
			elif [ -z "$watermark" ]; then
				watermark="$1"
			else
				error "Unknown parameter $1"
				usage
				exit 1
			fi
			;;
	esac
	shift
done


[ -f "$from" ] || {
    error "No filename"
    usage
	exit 1
}

[ -n "$watermark" ] || {
    error "No watermark"
    usage
	exit 1
}

[ -n "$to" ] || to="${destdir}/${from}"

nbcar=${#watermark}

if [ -f "$to" ] && [ "$force" != "yes" ] ; then
	error "Destination file exists $to"
	error "Use --dest-dir , --to ior --force parameters"
	usage
	exit 1
fi


"$convert" "$from" \
	\( -size $(( nbcar * 5 ))x -background none -fill "$color" -gravity center \
       label:"$watermark" -trim -rotate -30 \
       -bordercolor none -border 10 \
       -write mpr:wm +delete \
       +clone -fill mpr:wm  -draw 'color 0,0 reset' \) \
    -compose over -composite \
    "$to" \
	&& action "$to created" \
	|| error "$to not created"
