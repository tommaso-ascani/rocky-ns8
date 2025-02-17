#!/bin/bash

#
# Copyright (C) 2023 Nethesis S.r.l.
# SPDX-License-Identifier: GPL-3.0-or-later
#

set -e

if [[ $EUID != 0 ]]; then
    echo "This script must be executed with root privileges."
    exit 1
fi

# Ensure /usr/local/bin and /usr/local/sbin are in the PATH environment variable
if [[ ! "$PATH" =~ (^|:)/usr/local/bin(:|$) ]]; then
    export PATH=$PATH:/usr/local/bin
fi
if [[ ! "$PATH" =~ (^|:)/usr/local/sbin(:|$) ]]; then
    export PATH=$PATH:/usr/local/sbin
fi

echo "Checking the interface wg0 is not already in use"
if [ -e "/sys/class/net/wg0" ]; then
    echo "Installation failed: interface wg0 is already in use."
    exit 1
fi

echo "Checking port 80 and 443 are not already in use"
for port in 80 443
do
    if ss -H -l "( sport = :${port} )" | grep -q .; then
        echo "Installation failed: port ${port} is already in use."
        exit 1
    fi
done

echo "Restart journald:"
systemctl restart systemd-journald.service

source /etc/os-release

# Ensure local repository is configured
REPO_DIR="/mnt/nethserver-repo"
REPO_FILE="/etc/yum.repos.d/nethserver.repo"
NS8_CORE_IMAGE="/mnt/nethserver-repo/ns8-core.tar"

if [[ ! -f "$REPO_FILE" ]]; then
    echo "Creating local repository file at $REPO_FILE..."
    cat > "$REPO_FILE" <<EOF
[ns-local]
name=NS8 Local Repository
baseurl=file://$REPO_DIR/
enabled=1
gpgcheck=0
EOF
fi

dnf clean all
dnf --disablerepo="*" --enablerepo="ns-local" repolist

echo "Install dependencies:"
if [[ "${PLATFORM_ID}" == "platform:el9" ]]; then
    dnf --disablerepo="*" --enablerepo="ns-local" install /mnt/nethserver-repo/*.rpm -y
else
    echo "System not supported"
    exit 1
fi

echo "Extracting core sources from ${core_url}:"

podman load -i "${NS8_CORE_IMAGE}"
cid=$(podman create "ghcr.io/nethserver/core:ns8-stable")
podman export ${cid} | tar --totals -C / --no-overwrite-dir --no-same-owner --exclude=.gitignore --exclude-caches-under -x -v -f - | LC_ALL=C sort | tee coreimage.lst

mkdir -vp /var/lib/nethserver/node/state /var/lib/nethserver/cluster/state
chmod -c 0700 /var/lib/nethserver/node/state /var/lib/nethserver/cluster/state
mv -v coreimage.lst /var/lib/nethserver/node/state/coreimage.lst
podman rm -f ${cid}

/root/install_2.sh