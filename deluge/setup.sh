#!/bin/sh
JAIL_IP="192.168.1.72"
ROUTER="192.168.1.1"
RELEASE=$(freebsd-version | sed "s/STABLE/RELEASE/g")
JAIL_NAME="deluge"    
INTERFACE="vnet0"

LOCAL_CONFIG="/mnt/Tank/configs/deluge"
LOCAL_TRANSFER="/mnt/Tank/transfer/seeding"

JAIL_TRANSFER="/mnt/transfer"
JAIL_CONFIG="/mnt/config"

# Load config if present 
#SCRIPT=$(readlink -f "$0")
#SCRIPTPATH=$(dirname "${SCRIPT}")
#CONFIG_FILE="${SCRIPTPATH}"/local.conf

#if [ -f $CONFIG_FILE ]; then
#	. "$CONFIG_FILE"
#	echo "inside if"
#	echo "$JAIL_IP"
# exit	
#fi

# Create the jail
if ! iocage create --name "${JAIL_NAME}" -p ./pkg.json -r "${RELEASE}" ip4_addr="${INTERFACE}|${JAIL_IP}/24" defaultrouter="${ROUTER}" boot="on" host_hostname="${JAIL_NAME}" vnet="on"
then
	echo "Failed to create ${JAIL_NAME}"
	exit 1
fi

iocage exec "$JAIL_NAME" mkdir /deluge 

iocage exec "$JAIL_NAME" "pw user add media -c media -u 8675309 -d /media -s /usr/bin/nologin"
iocage exec "$JAIL_NAME" "pw user add deluge -c deluge -d /deluge -s /usr/bin/nologin"
iocage exec "$JAIL_NAME" "pw groupadd -n deluge"
iocage exec "$JAIL_NAME" "pw groupadd -n media -g 8675309"

# Create folders

iocage exec "$JAIL_NAME" mkdir -p "$JAIL_TRANSFER" "$JAIL_CONFIG"

# Mount folders
iocage fstab -a "$JAIL_NAME" "$LOCAL_TRANSFER" "$JAIL_TRANSFER" nullfs rw 0 0
iocage fstab -a "$JAIL_NAME" "$LOCAL_CONFIG" "$JAIL_CONFIG" nullfs rw 0 0

# Set permissions on mounted folders 
#iocage exec "$JAIL_NAME" chown -R media:media "$JAIL_TRANSFER" "$JAIL_CONFIG"

# Setup the deluge
iocage exec "$JAIL_NAME" sysrc deluged_enable=YES
iocage exec "$JAIL_NAME" sysrc deluged_user=media
iocage exec "$JAIL_NAME" sysrc deluged_group=media
iocage exec "$JAIL_NAME" sysrc deluged_confdir="$JAIL_CONFIG"

# Setup the deluge Web client
iocage exec "$JAIL_NAME" sysrc deluge_web_enable=YES
iocage exec "$JAIL_NAME" sysrc deluge_web_user=media
iocage exec "$JAIL_NAME" sysrc deluge_web_group=media
iocage exec "$JAIL_NAME" sysrc deluge_web_confdir="$JAIL_CONFIG"

# Start the services
iocage exec  "$JAIL_NAME" service deluged start
iocage exec  "$JAIL_NAME" service deluge_web start

# Restart Jail
iocage restart "$JAIL_NAME"
