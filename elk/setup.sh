#!/bin/sh
JAIL_IP="192.168.20.230"
ROUTER="192.168.20.1"
RELEASE=$(freebsd-version | sed "s/STABLE/RELEASE/g")
JAIL_NAME="elk"    
INTERFACE="vnet0"

LOCAL_CONFIG="/mnt/Tank/configs/elk"

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
if ! iocage create -n "${JAIL_NAME}" -p ./pkg.json -r "${RELEASE}" vnet="on" bpf="yes" allow_raw_sockets="1" boot="on"  ip4_addr="${INTERFACE}|${JAIL_IP}/24" defaultrouter="${ROUTER}" allow_mount="1" allow_mount_procfs="1" enforce_statfs="1" host_hostname="${JAIL_NAME}" 
then
	echo "Failed to create ${JAIL_NAME}"
	exit 1
fi

iocage exec "$JAIL_NAME" "pw user add media -c media -u 8675309 -d /media -s /usr/bin/nologin"
iocage exec "$JAIL_NAME" "pw user add deluge -c elk -d /elk -s /usr/bin/nologin"
iocage exec "$JAIL_NAME" "pw groupadd -n elk"
iocage exec nzbget "pw groupadd -n media -g 8675309"

# Create folders

iocage exec "$JAIL_NAME" mkdir -p "/proc" "$JAIL_CONFIG"

# Mount folders
iocage fstab -a "$JAIL_NAME" "proc" "/proc" procfs rw 0 0
iocage fstab -a "$JAIL_NAME" "$LOCAL_CONFIG" "$JAIL_CONFIG" nullfs rw 0 0

# Set permissions on mounted folders 
#iocage exec "$JAIL_NAME" chown -R media:media "$JAIL_TRANSFER" "$JAIL_CONFIG"

# Setup the deluge
iocage exec "$JAIL_NAME" sysrc elasticsearch_enable=YES
iocage exec "$JAIL_NAME" sysrc logstash_enable=YES
iocage exec "$JAIL_NAME" sysrc kibana_enable=YES
# iocage exec "$JAIL_NAME" sysrc deluged_user=media
# iocage exec "$JAIL_NAME" sysrc deluged_group=media
# iocage exec "$JAIL_NAME" sysrc deluged_confdir="$JAIL_CONFIG"

# Setup the deluge Web client
# iocage exec "$JAIL_NAME" sysrc deluge_web_enable=YES
# iocage exec "$JAIL_NAME" sysrc deluge_web_user=media
# iocage exec "$JAIL_NAME" sysrc deluge_web_group=media
# iocage exec "$JAIL_NAME" sysrc deluge_web_confdir="$JAIL_CONFIG"

# Update the kibana config
iocage exec "$JAIL_NAME" sed -i '' -e 's?#server.host: "localhost"?server.host: "$JAIL_IP"?g' /usr/local/etc/kibana/kibana.yml 
iocage exec "$JAIL_NAME" echo "xpack.reporting.enabled: false" > /usr/local/etc/kibana/kibana.yml 

# Start the services
iocage exec  "$JAIL_NAME" service elasticsearch start
iocage exec  "$JAIL_NAME" service logstash start
iocage exec  "$JAIL_NAME" service kibana start

# Restart Jail
iocage restart "$JAIL_NAME"
