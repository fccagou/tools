#!/usr/bin/bash

cd tmp/dst

iso_path=/home/fccagou/src/fccagou/tools/centos/tmp/socle.iso
log_file=/home/fccagou/src/fccagou/tools/centos/tmp/geniso.log

/usr/bin/genisoimage -o "${iso_path}" \
	 -b isolinux/isolinux.bin \
	 -c isolinux/boot.cat \
	 -no-emul-boot \
	 -V "socle" \
	 -boot-load-size 4  \
	 -boot-info-table   \
	 -R -J  -T ./ \
	 2>> "${log_file}" \
	 >> "${log_file}"



if [ $? == 0 ]
then
	printf "iso build in \n%s" "${iso_path}"
else

	printf "Error building \n%s" "${iso_path}"
	cat "${log_file}"
    exit 1
fi
