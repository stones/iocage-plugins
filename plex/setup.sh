JAIL_IP="192.168.1.50"
ROUTER="192.168.1.1"
RELEASE=$(freebsd-version | sed "s/STABLE/RELEASE/g")
JAIL_NAME="plex"    
INTERFACE="vnet0"

LOCAL_CONFIG="/mnt/Tank/configs/plex"
LOCAL_AUDIO="/mnt/Tank/library/audio"
LOCAL_VIDEO="/mnt/Tank/library/video"
LOCAL_IMAGES=" /mnt/Tank/library/images"

JAIL_CONFIG="/mnt/Tank/configs/plex"
JAIL_AUDIO="/mnt/Tank/library/audio"
JAIL_VIDEO="/mnt/Tank/library/video"
JAIL_IMAGES=" /mnt/Tank/library/images"

# Load config if present 
CONFIG_FILE=./local.conf

if [ -f "$CONFIG_FILE" ]; then
	. "$CONFIG_FILE"
fi


#Create the jail
if ! iocage create --name "${JAIL_NAME}" -p ./pkg.json -r "${RELEASE}" ip4_addr="${INTERFACE}|${JAIL_IP}/24" defaultrouter="${ROUTER}" boot="on" host_hostname="${JAIL_NAME}" vnet="on"
then
	echo "Failed to create ${JAIL_NAME}"
	exit 1
fi


# Add media user
iocage exec "$JAIL_NAME" "pw user add media -c media -u 8675309 -d /nonexistent -s /usr/bin/nologin"
iocage exec "$JAIL_NAME" "pw groupmod media -m plex"

# Set updates to be more frequent
iocage exec "$JAIL_NAME" "mkdir -p /usr/local/etc/pkg/repos"
iocage exec "$JAIL_NAME" echo -e 'FreeBSD: { url: "pkg+http://pkg.FreeBSD.org/\${ABI}/latest\" }' > /usr/local/etc/pkg/repos/FreeBSD.conf

iocage exec "$JAIL_NAME" "pkg upgrade"

# Mount volumes
iocage fstab -a "$JAIL_NAME" "$LOCAL_CONFIG" "$JAIL_CONFIG" nullfs rw 0 0
iocage fstab -a "$JAIL_NAME" "$LOCAL_AUDIO" "$JAIL_AUDIO" nullfs rw 0 0
iocage fstab -a "$JAIL_NAME" "$LOCAL_VIDEO" "$JAIL_VIDEO" nullfs rw 0 0
iocage fstab -a "$JAIL_NAME" "$LOCAL_IMAGES" /mnt/images nullfs rw 0 0

# Change permissions
iocage exec "$JAIL_NAME" chown -R media:media "$LOCAL_CONFIG"

# Enable plex on start
iocage exec "$JAIL_NAME" sysrc "plexmediaserver_plexpass_enable=YES"
iocage exec "$JAIL_NAME" sysrc plexmediaserver_plexpass_support_path="/mnt/config"
iocage exec "$JAIL_NAME" sysrc plexmediaserver_plexpass_user="media"
iocage exec "$JAIL_NAME" service plexmediaserver_plexpass start

# Copy updater files
if [[ -z "$PLEXPASS_USER" && -z "$PLEXPASS_PASSWORD" ]]; then
iocage exec "$JAIL_NAME" wget -O ~/PMS_Updater.sh https://raw.githubusercontent.com/mstinaff/PMS_Updater/master/PMS_Updater.sh
iocage exec "$JAIL_NAME" chmod 755 ~/PMS_Updater.sh
iocage exec "$JAIL_NAME" echo "user=$PLEXPASS_USER" > ~/creds.txt
iocage exec "$JAIL_NAME" echo "password=$PLEXPASS_PASSWORD" >> ~/creds.txt

iocage exec "$JAIL_NAME" ~/PMS_Updater.sh -c ~/creds.txt -vf
iocage exec "${JAIL_NAME}" echo "0 2 * * * ~/PMS_Updater.sh -c ~/creds.txt -vf >> ~/.updater-log" | crontab -
fi

iocage restart plex
