#!/bin/sh
DEFAULT_ROUTER="192.168.1.200"
JAIL_FOLDER="/mnt/iocage/jails"
JAIL_INTERFACE="vnet0"
JAIL_IP="192.168.1.220"
JAIL_NAME="reverse-proxy"
RELEASE="$(freebsd-version | sed "s/STABLE/RELEASE/g")"

# Create the jail
iocage create -n $JAIL_NAME -p ./pkg.json -r $RELEASE ip4_addr="$JAIL_INTERFACE|$JAIL_IP/24" defaultrouter="$DEFAULT_ROUTER" vnet="on" allow_raw_sockets="1" boot="on" 

# Add config folder
iocage exec "$JAIL_NAME" mkdir -p /mnt/config
iocage fstab -a "$JAIL_NAME" /mnt/Tank/configs/reverse-proxy /mnt/config nullfs rw 0 0