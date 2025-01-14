mkdir /tmp/custom_iso

cd /tmp/custom_iso/

sudo mount -t iso9660 -o loop ~/Documents/nethesis/kickstart/Rocky-x86_64-minimal.iso /mnt/

cd /mnt

sudo tar cf - . | (cd /tmp/custom_iso; tar xfp -)