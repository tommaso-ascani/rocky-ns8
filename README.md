# Creating the minimal ISO image

- Download the ISO image from the site: [Rocky Linux Download](https://rockylinux.org/download)
- Build the container file with the following command:
   ```sh
   buildah build -t ns8-boxbuilder .
   ```
- Create the container that modifies the minimal ISO of Rocky Linux with the following command:
   ```sh
   podman run --rm -it --privileged -v $(pwd):/root localhost/ns8-boxbuilder mkksiso --cmdline "inst.ks=https://raw.githubusercontent.com/tommaso-ascani/rocky-ns8/refs/heads/main/ks.cfg" <downloaded_image_name>.iso ns8.iso
   ```
   > **Note:** Replace `<downloaded_image_name>` with the name of the downloaded ISO image.

# Create bootable USB

- List block devices to identify the USB drive:
   ```sh
   lsblk
   ```
- Write the ISO file to the USB drive:
   ```sh
   sudo dd if=./ns8.iso of=/dev/* bs=4M status=progress && sync
   ```
- Eject the USB drive:
   ```sh
   sudo eject /dev/*
   ```