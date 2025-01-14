cd /tmp/custom_iso

mkisofs -o ~/Documents/nethesis/kickstart/Rocky9-modified.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -R -V "Rocky 9 - NS8 install" .