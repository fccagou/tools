# Création de partition persistente pour Kali

Ref: site web de Kali


Hop une clef usb Kali.

   mkfs.vfat -F32 -Iv /dev/sdb
   dd if=kali-linux-2019-2-amd64.iso of=/dev/sdb bs=512k

Création de la partition persistente

   end=14gb
   read start _ < <(du -bcm kali-linux-2019.2-amd64.iso | tail -1); echo $start
   parted /dev/sdb mkpart primary $start $end

Version non chiffrée

   mkfs.ext3 -L persistence /dev/sdb3
   e2label /dev/sdb3 persistence
   mkdir -p /mnt/my_usb
   mount /dev/sdb3 /mnt/my_usb
   echo "/ union" > /mnt/my_usb/persistence.conf
   umount /dev/sdb3

Version chifréé avec luks

   cryptsetup --verbose --verify-passphrase luksFormat /dev/sdb3
   cryptsetup luksOpen /dev/sdb3 my_usb
   mkfs.ext3 -L persistence /dev/mapper/my_usb
   e2label /dev/mapper/my_usb persistence
   mkdir -p /mnt/my_usb
   mount /dev/mapper/my_usb /mnt/my_usb
   echo "/ union" > /mnt/my_usb/persistence.conf
   umount /dev/mapper/my_usb
   cryptsetup luksClose /dev/mapper/my_usb

