Some doc and tools about kvm.


Clone kvm host and update data


 virt-clone --connect qemu:///system --original c7-socle --name c7-zeek --file /srv/virtu/libvirt/images/c7-zeek.img
 guestfish --ro -i -d c7-socle  cat /etc/shadow




