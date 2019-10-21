#!/bin/sh
JAIL_IP="192.168.20.205"
ROUTER="192.168.20.1"
RELEASE=$(freebsd-version | sed "s/STABLE/RELEASE/g")
JAIL_NAME="nzbget"    
INTERFACE="vnet0"

LOCAL_CONFIG="/mnt/Tank/configs/nzbget"
LOCAL_TRANSFER="/mnt/Tank/transfer"

JAIL_TRANSFER="/mnt/transfer"
JAIL_CONFIG="/mnt/config"

JAILS_FOLDER="/mnt/iocage/jails"

if ! iocage create --name "${JAIL_NAME}" -p ./pkg.json -r "${RELEASE}" ip4_addr="${INTERFACE}|${JAIL_IP}/24" defaultrouter="${ROUTER}" boot="on" host_hostname="${JAIL_NAME}" vnet="on"
then
	echo "Failed to create ${JAIL_NAME}"
	exit 1
fi


# Add media user
iocage exec "$JAIL_NAME" "pw user add media -c media -u 8675309 -d /nonexistent -s /usr/bin/nologin"
iocage exec "$JAIL_NAME" "pw groupadd -n media -g 8675309"
iocage exec "$JAIL_NAME" "pw groupmod media -m nzbget"

# Ensure the rc.d folder exists
iocage exec "$JAIL_NAME" mkdir -p /usr/local/etc/rc.d

# Copy the nzbget file so we can use 'service nzbget start|stop|etc'
cp ./nzbget.rc  "$JAILS_FOLDER/$JAIL_NAME/root/etc/rc.d/nzbget"
# Set permissions
iocage exec "$JAIL_NAME" chmod 555 /etc/rc.d/nzbget

#Ensure folders exiset
iocage exec "$JAIL_NAME" mkdir -p "$JAIL_TRANSFER" "$JAIL_CONFIG"

# Mount folders
iocage fstab -a "$JAIL_NAME" "$LOCAL_TRANSFER" "$JAIL_TRANSFER" nullfs rw 0 0
iocage fstab -a "$JAIL_NAME" "$LOCAL_CONFIG" "$JAIL_CONFIG" nullfs rw 0 0

# Download nzbget install script
iocage exec "$JAIL_NAME" "fetch https://nzbget.net/download/nzbget-latest-bin-freebsd.run"
# install nzbget
iocage exec "$JAIL_NAME" "sh nzbget-latest-bin-freebsd.run --destdir /usr/local/share/nzbget"
# remove install script
iocage exec "$JAIL_NAME" rm nzbget-latest-bin-freebsd.run 
# Set permissions on mounted folders 
iocage exec "$JAIL_NAME" chown -R media:media /mnt/transfer /mnt/config /usr/local/share/nzbget
# Enable nzbget
iocage exec "$JAIL_NAME" sysrc "nzbget_user=media"
iocage exec "$JAIL_NAME" sysrc "nzbget_enable=YES"
# Restart the jail
iocage restart "$JAIL_NAME"