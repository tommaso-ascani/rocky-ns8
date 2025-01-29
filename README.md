# Creating the minimal ISO image

- Download the ISO image from the site: [Rocky Linux Download](https://rockylinux.org/download)
- Build the container file with the following command:
   ```sh
   buildah build -t ns8-boxbuilder .
   ```
- Create the container that modifies the minimal ISO of Rocky Linux with the following command:
   ```sh
   podman run --rm -it --privileged -v $(pwd):/root localhost/ns8-boxbuilder mkksiso -R "Rocky Linux" "NethServer 8 (Rocky Linux)" --cmdline "inst.ks=https://raw.githubusercontent.com/NethServer/ns8-rocky-iso/refs/heads/main/ks.cfg" <downloaded_image_name>.iso ns8.iso
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

# Verifying Installation

- After the installation, verify that the system has rebooted and the NethServer 8 installation completed successfully.
- Check the installation log for details:
   ```sh
   cat /var/log/ns8-install.log
   ```

# Default Configurations

## Console
- **User:** `root`
- **Password:** `Nethesis,1234`

## Cluster
- **User:** `admin`
- **Password:** `Nethesis,1234`

## OpenLDAP
- **User:** `administrator`
- **Password:** `Nethesis,1234`