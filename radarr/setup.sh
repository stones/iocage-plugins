#!/bin/sh
JAIL_IP="192.168.20.211"
ROUTER="192.168.20.1"
RELEASE=$(freebsd-version | sed "s/STABLE/RELEASE/g")
JAIL_NAME="radarr"    
INTERFACE="vnet0"

LOCAL_CONFIG="/mnt/Tank/configs/radarr"
LOCAL_TRANSFER="/mnt/Tank/transfer/complete/movies"
LOCAL_LIBRARY="/mnt/Tank/library/video/movies"

JAIL_TRANSFER="/mnt/transfer"
JAIL_LIBRARY="/mnt/library"
JAIL_CONFIG="/mnt/config"

JAILS_FOLDER="/mnt/iocage/jails"

# Create jail
if ! iocage create --name "${JAIL_NAME}" -p ./pkg.json -r "${RELEASE}" ip4_addr="${INTERFACE}|${JAIL_IP}/24" defaultrouter="${ROUTER}" boot="on" host_hostname="${JAIL_NAME}" vnet="on"
then
	echo "Failed to create ${JAIL_NAME}"
	exit 1
fi

# Update to Latest Repo
# iocage exec "$JAIL_NAME" "mkdir -p /usr/local/etc/pkg/repos"
# iocage exec "$JAIL_NAME" echo -e 'FreeBSD: { url: "pkg+http://pkg.FreeBSD.org/\${ABI}/latest\" }' > /usr/local/etc/pkg/repos/FreeBSD.conf

# iocage exec "$JAIL_NAME" "pkg upgrade"

# Ensure mount folders exist
iocage exec "$JAIL_NAME" mkdir -p "$JAIL_TRANSFER" "$JAIL_CONFIG" "$JAIL_LIBRARY"

# iocage exec "$JAIL_NAME" pkg update && pkg upgrade
iocage fstab -a "$JAIL_NAME" "$LOCAL_LIBRARY" "$JAIL_LIBRARY" nullfs rw 0 0
iocage fstab -a "$JAIL_NAME" "$LOCAL_TRANSFER" "$JAIL_TRANSFER" nullfs rw 0 0
iocage fstab -a "$JAIL_NAME" "$LOCAL_CONFIG" "$JAIL_CONFIG" nullfs rw 0 0

# Link mono
iocage exec "$JAIL_NAME" ln -s /usr/local/bin/mono /usr/bin/mono

# Download "$JAIL_NAME"
iocage exec "$JAIL_NAME" "fetch https://github.com/Radarr/Radarr/releases/download/v0.2.0.1217/Radarr.v0.2.0.1217.linux.tar.gz -o /usr/local/share"
iocage exec "$JAIL_NAME" "tar -xzvf /usr/local/share/Radarr.v0.2.0.1217.linux.tar.gz -C /usr/local/share"
iocage exec "$JAIL_NAME" rm /usr/local/share/Radarr.v0.2.0.1217.linux.tar.gz

## Media Permissions
iocage exec "$JAIL_NAME" "pw user add radarr -c radarr -u 352 -d /nonexistent -s /usr/bin/nologin"

# Create users
iocage exec "$JAIL_NAME" "pw user add media -c media -u 8675309 -d /nonexistent -s /usr/bin/nologin"
iocage exec "$JAIL_NAME" "pw groupadd -n media -g 8675309"
iocage exec "$JAIL_NAME" "pw groupmod media -m radarr"
iocage exec "$JAIL_NAME" chown -R media:media /usr/local/share/Radarr "$JAIL_CONFIG"

# Copy sysrc
iocage exec "$JAIL_NAME" mkdir -p /usr/local/etc/rc.d
cp ./radarr.rc  "$JAILS_FOLDER/$JAIL_NAME/root/usr/local/etc/rc.d/radarr"

iocage exec "$JAIL_NAME" chmod u+x /usr/local/etc/rc.d/radarr

iocage exec "$JAIL_NAME" sysrc "radarr_enable=YES"
iocage exec "$JAIL_NAME" sysrc "radarr_user=media"

iocage exec "$JAIL_NAME" service radarr start