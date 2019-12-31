#!/bin/sh
JAIL_IP="192.168.20.214"
ROUTER="192.168.20.1"
RELEASE=$(freebsd-version | sed "s/STABLE/RELEASE/g")
JAIL_NAME="mylar"    
INTERFACE="vnet0"

LOCAL_CONFIG="/mnt/Tank/configs/mylar"
LOCAL_TRANSFER="/mnt/Tank/transfer/complete/comics"
LOCAL_LIBRARY="/mnt/Tank/library/print/comics"

JAIL_TRANSFER="/mnt/transfer"
JAIL_LIBRARY="/mnt/library"
JAIL_CONFIG="/mnt/config"

JAILS_FOLDER="/mnt/iocage/jails"

JAIL_RC = "/usr/local/etc/rc.d/mylar"

# Create jail
if ! iocage create --name "${JAIL_NAME}" -p ./pkg.json -r "${RELEASE}" ip4_addr="${INTERFACE}|${JAIL_IP}/24" defaultrouter="${ROUTER}" boot="on" host_hostname="${JAIL_NAME}" vnet="on"
then
	echo "Failed to create ${JAIL_NAME}"
	exit 1
fi

# link python 
iocage exec "$JAIL_NAME" "ln -s /usr/local/bin/python2.7 /usr/local/bin/python"

# Ensure mount folders exist
iocage exec "$JAIL_NAME" mkdir -p "$JAIL_TRANSFER" "$JAIL_CONFIG" "$JAIL_LIBRARY"

# Mount folders
iocage fstab -a "$JAIL_NAME" "$LOCAL_LIBRARY" "$JAIL_LIBRARY" nullfs rw 0 0
iocage fstab -a "$JAIL_NAME" "$LOCAL_TRANSFER" "$JAIL_TRANSFER" nullfs rw 0 0
iocage fstab -a "$JAIL_NAME" "$LOCAL_CONFIG" "$JAIL_CONFIG" nullfs rw 0 0

# Add media user
iocage exec "$JAIL_NAME" "pw user add media -c media -u 8675309 -d /nonexistent -s /usr/bin/nologin"

iocage exec "$JAIL_NAME" git clone https://github.com/evilhero/mylar.git /usr/local/mylar
iocage exec "$JAIL_NAME" chown -R media:media /usr/local/mylar

# Copy service file
cp ./lidarr.rc  "$JAILS_FOLDER/$JAIL_NAME/root$JAIL_RC"
iocage exec "$JAIL_NAME" chmod u+x "$JAIL_RC"

# Start services
iocage exec "$JAIL_NAME" sysrc mylar_enable=YES
iocage exec "$JAIL_NAME" sysrc mylar_user=media
iocage exec "$JAIL_NAME" sysrc mylar_group=media

iocage exec "$JAIL_NAME" service mylar start
