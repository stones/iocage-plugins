JAIL_IP="192.168.1.2"
ROUTER="192.168.1.1"
RELEASE=$(freebsd-version | sed "s/STABLE/RELEASE/g")
JAIL_NAME="qbtorrent"    
INTERFACE="vnet0"

LOCAL_CONFIG="/mnt/Tank/configs/qbittorrent"
LOCAL_TRANSFER="/mnt/Tank/transfer/seeding"

JAIL_TRANSFER="/mnt/transfer"
JAIL_CONFIG="/mnt/config"

# Load config if present 
CONFIG_FILE=./local.conf

if [ -f "$CONFIG_FILE" ]; then
	. "$CONFIG_FILE"
fi

# Create the jail
if ! iocage create --name "${JAIL_NAME}" -p ./pkg.json -r "${RELEASE}" ip4_addr="${INTERFACE}|${JAIL_IP}/24" defaultrouter="${ROUTER}" boot="on" host_hostname="${JAIL_NAME}" vnet="on"
then
	echo "Failed to create ${JAIL_NAME}"
	exit 1
fi

# Create folders
iocage exec "$JAIL_NAME" mkdir -p "$JAIL_TRANSFER" "$JAIL_CONFIG"

# Mount folders
iocage fstab -a "$JAIL_NAME" "$LOCAL_TRANSFER" "$JAIL_TRANSFER" nullfs rw 0 0
iocage fstab -a "$JAIL_NAME" "$LOCAL_CONFIG" "$JAIL_CONFIG" nullfs rw 0 0

# Set permissions on mounted folders 
iocage exec "$JAIL_NAME" chown -R media:media "$JAIL_TRANSFER" "$JAIL_CONFIG"

# auto start after jail reboot
iocage exec "$JAIL_NAME" echo /usr/local/bin/qbittorrent-nox -d --profile="$JAIL_CONFIG" >> /etc/rc.conf

# First start
iocage exec "$JAIL_NAME" /usr/local/bin/qbittorrent-nox -d --profile="$JAIL_CONFIG"

# Restart Jail
iocage restart "$JAIL_NAME"