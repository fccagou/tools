

error () {
	echo -e "[-] ${@}"
}

image="${1:-undef}"


if [ ! -f "${image}" ]
then
	error "file not found $image"
    exit 1
fi

if [ -z "$(file "$image" | cut -d: -f2 | grep -i "zip archive")" ]
then
	error "file $image is not a zip archive"
    exit 1
fi

cat <<EOF_PRINT
unsip -p "${image}" | dd of=/dev/sdX bs=4M conv=fsync status=progress"
EOF_PRINT

