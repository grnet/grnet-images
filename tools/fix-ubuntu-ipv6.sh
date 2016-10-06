#!/bin/bash

# Copyright (C) 2016 GRNET S.A.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.

set -e

RED='\e[1;31m'
GREEN='\e[1;32m'
RESET='\e[0m'
PROG="$(realpath $0)"

error() { echo -e "${RED}Error: $@${RESET}"  >&2; exit 1; }
success() { echo -e "${GREEN}$@${RESET}" >&2; }

if [ "$(which lsb_release)"  = "" ]; then
    error "lsb_release command needed but missing"
fi

OS=$(lsb_release -i | awk '{ print $3; }')
VERSION=$(lsb_release -r | awk '{ print $2; }')

if [ "$OS" != Ubuntu -o "$VERSION" != "16.04" ]; then
    error "This script must run only on an Ubuntu 16.04 system."
fi

if ! pgrep NetworkManager &>/dev/null; then
    error "Network Manager does not seem to be running on the system."
fi

if [ $UID != 0 ]; then
    exec sudo bash "$PROG"
fi

echo -n "Commenting out /etc/network/interfaces... "
sed -i 's/^\([^#]\)/#\1/g' /etc/network/interfaces
success "done"
 
echo -n "Finding first NIC in the system... "
PCI=$(lspci -m | grep "Ethernet controller" | cut -f1 -d" " |sort | head -1)
NIC=$(ls /sys/devices/pci0000\:00/0000\:$PCI/virtio*/net/)
MAC=$(cat /sys/devices/pci0000\:00/0000\:$PCI/virtio*/net/$NIC/address)
success "$NIC"

# check if an NM connection for the first NIC is present
for i in /etc/NetworkManager/system-connections/*; do
    if grep -i ${MAC} "$i" &>/dev/null; then
        mode=$(grep ^addr-gen-mode "$i" | cut -d= -f2)
        if [ "$mode" = eui64 ]; then
            success "Your system is already patched!"
            exit 0
        else
            echo -n "Removing connection: \`$i'... "
            rm -f "$i"
            success "done"
        fi
    fi
done

echo -n "Creating connection for $NIC... "
CONNECTION="/etc/NetworkManager/system-connections/Wired IPv6 connection"
cat > "$CONNECTION" <<EOF
[connection]
id=Wired IPv6 connection
uuid=$(cat /proc/sys/kernel/random/uuid)
type=ethernet
autoconnect=true

[ethernet]
mac-address=${MAC^^}

[ipv4]
dns-search=
method=disabled

[ipv6]
addr-gen-mode=eui64
dns-search=
method=auto
EOF
success "done"

chmod 600 "$CONNECTION"

echo -n "Reloading NM connections... "
nmcli con reload
success "done"

