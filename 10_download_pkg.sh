#!/bin/bash

set -e

# Configuration
REPO_DIR="/mnt/nethserver-repo"
CORE_IMAGE="ghcr.io/nethserver/core:ns8-stable"
CORE_ARCHIVE="/mnt/nethserver-repo/ns8-core.tar"

echo "Starting setup..."

# Ensure required packages are installed
if ! command -v dnf &> /dev/null; then
    echo "Error: dnf is not available. Ensure you are running this script on a compatible system."
    exit 1
fi

# Install createrepo if not available
if ! command -v createrepo &> /dev/null; then
    echo "Installing createrepo..."
    dnf install -y createrepo
fi

# Create repository metadata
echo "Creating local directory at $REPO_DIR..."
mkdir -p "$REPO_DIR"

if [[ ! -d "$REPO_DIR/repodata" ]]; then
    echo "Creating repository metadata..."
    createrepo "$REPO_DIR"
fi

# Install podman if not available
if ! command -v podman &> /dev/null; then
    echo "Installing podman..."
    dnf install -y podman
fi

# Download required packages if not already present
echo "Downloading required packages..."
for pkg in wireguard-tools podman curl jq openssl firewalld pciutils python3.11; do
    if ! ls "$REPO_DIR/${pkg}"*.rpm &> /dev/null; then
        echo "Downloading $pkg..."
        dnf download --resolve --destdir="$REPO_DIR" "$pkg"
    else
        echo "$pkg is already downloaded."
    fi
done

# Update Python to version 3.11
echo "Updating Python to version 3.11..."
dnf install -y python3.11

# Ensure pip is installed
if ! command -v pip3.11 &> /dev/null; then
    echo "Installing pip..."
    dnf install -y python3.11-pip
fi

# Download pyreq3_11.txt file
PYREQ_URL="https://raw.githubusercontent.com/NethServer/ns8-core/refs/heads/main/core/imageroot/etc/nethserver/pyreq3_11.txt"
PYREQ_FILE="/etc/nethserver/pyreq3_11.txt"
mkdir -p "$(dirname "$PYREQ_FILE")"
curl -o "$PYREQ_FILE" "$PYREQ_URL"

# Download Python packages required for the virtual environment
echo "Downloading Python packages..."
PYTHON_PKG_DIR="$REPO_DIR/python_packages"
mkdir -p "$PYTHON_PKG_DIR"
pip3.11 download -d "$PYTHON_PKG_DIR" -r "$PYREQ_FILE"

# Create a wheel package for the virtual environment
pip3.11 download --dest /mnt/nethserver-repo/python_packages wheel

# Save NS8 core container archive if not present
if [[ ! -f "$CORE_ARCHIVE" ]]; then
    echo "Saving NS8 core container..."
    podman pull "$CORE_IMAGE"
    podman save -o "$CORE_ARCHIVE" "$CORE_IMAGE"
else
    echo "NS8 core container is already saved."
fi

# Extract and download additional images from the NS8 core container archive
echo "Extracting and downloading additional images..."

# Ensure the ns8_images directory exists
mkdir -p "$REPO_DIR/ns8_images"

for image in $(
    podman inspect "${CORE_IMAGE}" | jq -r '.[0].Labels["org.nethserver.images"]'
); do
    image_archive="$REPO_DIR/ns8_images/$(basename "$image" | tr ':' '_').tar"
    if [[ ! -f "$image_archive" ]]; then
        echo "Saving $image..."
        podman pull "$image"
        podman save -o "$image_archive" "$image"
    else
        echo "$image is already saved."
    fi
done

dnf clean all
dnf repolist

echo "Setup complete. Packages and container are ready to be included in the ISO."

/root/network_off.sh
/root/install_1.sh