#!/bin/sh
JAIL_IP="192.168.20.212"
ROUTER="192.168.20.1"
RELEASE=$(freebsd-version | sed "s/STABLE/RELEASE/g")
JAIL_NAME="lidarr"    
INTERFACE="vnet0"

LOCAL_CONFIG="/mnt/Tank/configs/lidarr"
LOCAL_TRANSFER="/mnt/Tank/transfer/complete/music"
LOCAL_LIBRARY="/mnt/Tank/library/audio/music"

JAIL_TRANSFER="/mnt/transfer"
JAIL_LIBRARY="/mnt/library"
JAIL_CONFIG="/mnt/config"

JAILS_FOLDER="/mnt/iocage/jails"

JAIL_RC = "/usr/local/etc/rc.d/lidarr"

# Create Jail

if ! iocage create --name "${JAIL_NAME}" -p ./pkg.json -r "${RELEASE}" ip4_addr="${INTERFACE}|${JAIL_IP}/24" defaultrouter="${ROUTER}" boot="on" host_hostname="${JAIL_NAME}" vnet="on"
then
	echo "Failed to create ${JAIL_NAME}"
	exit 1
fi

# Update to Latest Repo
# iocage exec "$JAIL_NAME" "mkdir -p /usr/local/etc/pkg/repos"
# iocage exec "$JAIL_NAME" echo -e 'FreeBSD: { url: "pkg+http://pkg.FreeBSD.org/\${ABI}/latest\" }' > /usr/local/etc/pkg/repos/FreeBSD.conf

# iocage exec "$JAIL_NAME" "pkg upgrade"

# Install pkgs
# iocage exec "$JAIL_NAME" pkg update && pkg upgrade

# Ensure mount folders exist
iocage exec "$JAIL_NAME" mkdir -p "$JAIL_TRANSFER" "$JAIL_CONFIG" "$JAIL_LIBRARY"

iocage fstab -a "$JAIL_NAME" "$LOCAL_LIBRARY" "$JAIL_LIBRARY" nullfs rw 0 0
iocage fstab -a "$JAIL_NAME" "$LOCAL_TRANSFER" "$JAIL_TRANSFER" nullfs rw 0 0
iocage fstab -a "$JAIL_NAME" "$LOCAL_CONFIG" "$JAIL_CONFIG" nullfs rw 0 0

# Link mono
iocage exec "$JAIL_NAME" ln -s /usr/local/bin/mono /usr/bin/mono

# Download lidarr
iocage exec "$JAIL_NAME" "fetch https://github.com/lidarr/Lidarr/releases/download/v0.5.0.583/Lidarr.develop.0.5.0.583.linux.tar.gz -o /usr/local/share"
iocage exec "$JAIL_NAME" "tar -xzvf /usr/local/share/Lidarr.develop.0.5.0.583.linux.tar.gz  -C /usr/local/share"
iocage exec "$JAIL_NAME" rm /usr/local/share/Lidarr.develop.0.5.0.583.linux.tar.gz

## Media Permissions
iocage exec "$JAIL_NAME" "pw user add "$JAIL_NAME" -c "$JAIL_NAME" -u 352 -d /nonexistent -s /usr/bin/nologin"

# Create users
iocage exec "$JAIL_NAME" "pw user add media -c media -u 8675309 -d /nonexistent -s /usr/bin/nologin"
iocage exec "$JAIL_NAME" "pw groupadd -n media -g 8675309"
iocage exec "$JAIL_NAME" "pw groupmod media -m lidarr"
iocage exec "$JAIL_NAME" chown -R media:media /usr/local/share/Lidarr "$JAIL_CONFIG"

# Copy sysrc
iocage exec "$JAIL_NAME" mkdir -p /usr/local/etc/rc.d
cp ./lidarr.rc  "$JAILS_FOLDER/$JAIL_NAME/root$JAIL_RC"
iocage exec "$JAIL_NAME" chmod u+x "$JAIL_RC"

iocage exec "$JAIL_NAME" sysrc "lidarr_enable=YES"
iocage exec "$JAIL_NAME" sysrc "lidarr_user=media"

iocage exec "$JAIL_NAME" service lidarr start