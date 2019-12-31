#!/bin/sh
JAIL_IP="192.168.20.210"
ROUTER="192.168.20.1"
RELEASE=$(freebsd-version | sed "s/STABLE/RELEASE/g")
JAIL_NAME="sonarr"    
INTERFACE="vnet0"

LOCAL_CONFIG="/mnt/Tank/configs/sonarr"
LOCAL_TRANSFER="/mnt/Tank/transfer/complete/television"
LOCAL_LIBRARY="/mnt/Tank/library/video/tv"

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

# Add media user
iocage exec "$JAIL_NAME" "pw user add media -c media -u 8675309 -d /nonexistent -s /usr/bin/nologin"
iocage exec "$JAIL_NAME" "pw groupadd -n media -g 8675309"
iocage exec "$JAIL_NAME" "pw groupmod media -m sonarr"

iocage exec "$JAIL_NAME" mkdir /usr/local/etc/rc.d
cp ./sonarr.rc  "$JAILS_FOLDER/$JAIL_NAME/root/usr/local/etc/rc.d/sonarr"
iocage exec "$JAIL_NAME" chmod 555 /usr/local/etc/rc.d/sonarr

# Ensure mount folders exist
iocage exec "$JAIL_NAME" mkdir -p "$JAIL_TRANSFER" "$JAIL_CONFIG" "$JAIL_LIBRARY"

# Mount folders
iocage fstab -a "$JAIL_NAME" "$LOCAL_LIBRARY" "$JAIL_LIBRARY" nullfs rw 0 0
iocage fstab -a "$JAIL_NAME" "$LOCAL_TRANSFER" "$JAIL_TRANSFER" nullfs rw 0 0
iocage fstab -a "$JAIL_NAME" "$LOCAL_CONFIG" "$JAIL_CONFIG" nullfs rw 0 0

iocage exec "$JAIL_NAME" ln -s /usr/local/bin/mono /usr/bin/mono

# Install sonarr
iocage exec "$JAIL_NAME" "fetch http://download.sonarr.tv/v2/master/mono/NzbDrone.master.tar.gz -o /usr/local/share"
iocage exec "$JAIL_NAME" "tar -xzvf /usr/local/share/NzbDrone.master.tar.gz -C /usr/local/share"
iocage exec "$JAIL_NAME" rm /usr/local/share/NzbDrone.master.tar.gz

iocage exec "$JAIL_NAME" chown -R media:media /usr/local/share/NzbDrone "$JAIL_CONFIG"

# Initialise the service
iocage exec "$JAIL_NAME" sysrc "sonarr_enable=YES"
iocage exec "$JAIL_NAME" service sonarr start
