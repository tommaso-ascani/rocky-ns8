#!/bin/bash

#
# Copyright (C) 2023 Nethesis S.r.l.
# http://www.nethesis.it - nethserver@nethesis.it
#
# This script is part of NethServer.
#
# NethServer is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License,
# or any later version.
#
# NethServer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with NethServer.  If not, see COPYING.
#

set -e

#
# Install NS8
#

NS8_CORE_IMAGE="/mnt/nethserver-repo/ns8-core.tar"

source /etc/nethserver/core.env

CORE_IMAGE="ghcr.io/nethserver/core:ns8-stable"

echo "Loading core images from local files:"
if [[ -f ${NS8_CORE_IMAGE} ]]; then
    podman load -i ${NS8_CORE_IMAGE}
else
    echo "Core image file not found!"
    exit 1
fi

echo "Loading additional images from /mnt/nethserver-repo/ns8_images:"
for tar_file in /mnt/nethserver-repo/ns8_images/*.tar; do
    if [[ -f ${tar_file} ]]; then
        podman load -i ${tar_file}
    else
        echo "No additional tar files found in /mnt/nethserver-repo/ns8_images/"
        break
    fi
done

echo "Set kernel parameters:"
sysctl -w net.ipv4.ip_unprivileged_port_start=23 -w user.max_user_namespaces=28633 -w net.ipv4.ip_forward=1 | tee /etc/sysctl.d/80-nethserver.conf

if ! id "api-server" &>/dev/null; then
    echo "Create the api-server user:"
    useradd -r -m -d /var/lib/nethserver/api-server api-server
fi

echo "Setup Python virtual environment for agents:"
core_dir=/usr/local/agent/pyenv
python3.11 -mvenv ${core_dir} --system-site-packages
${core_dir}/bin/pip3 install --no-index --find-links=file:///mnt/nethserver-repo/python_packages -r /etc/nethserver/pyreq3_11.txt
echo "/usr/local/agent/pypkg" >$(${core_dir}/bin/python3 -c "import sys; print(sys.path[-1] + '/pypkg.pth')")

echo "Setup registry:"
if [[ ! -f /etc/nethserver/registry.json ]] ; then
    echo '{"auths":{}}' > /etc/nethserver/registry.json
fi

echo "Add firewalld core rules:"
(
    exec >/dev/null
    firewall-cmd --permanent --add-service=http --add-service=https
    firewall-cmd --reload
)

echo "Write initial cluster environment state"
(exec > /var/lib/nethserver/cluster/state/environment
    printf "NODE_ID=1\n"
)

echo "Write initial node environment state"
(exec > /var/lib/nethserver/node/state/environment
    printf "NODE_ID=1\n"
    printf "IMAGE_URL=%s\n" "${CORE_IMAGE}"
    printf "IMAGE_ID=%s\n" $(podman image inspect -f '{{.Id}}' "${CORE_IMAGE}")
    printf "IMAGE_DIGEST=%s\n" $(podman image inspect -f '{{.Digest}}' "${CORE_IMAGE}")
    printf "IMAGE_REPODIGEST=%s\n" $(podman image inspect -f '{{index .RepoDigests 0}}' "${CORE_IMAGE}")
    printf "PREV_IMAGE_URL=%s\n" "${CORE_IMAGE}"
    printf "PREV_IMAGE_ID=%s\n" $(podman image inspect -f '{{.Id}}' "${CORE_IMAGE}")
    printf "PREV_IMAGE_DIGEST=%s\n" $(podman image inspect -f '{{.Digest}}' "${CORE_IMAGE}")
    printf "PREV_IMAGE_REPODIGEST=%s\n" $(podman image inspect -f '{{index .RepoDigests 0}}' "${CORE_IMAGE}")
)

if [[ -z "${NS8_TWO_STEPS_INSTALL}" ]]; then
       /var/lib/nethserver/node/install-finalize.sh "$@"
fi