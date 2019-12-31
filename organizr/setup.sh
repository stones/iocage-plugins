#!/bin/sh
JAIL_IP="192.168.20.221"
ROUTER="192.168.20.1"
RELEASE=$(freebsd-version | sed "s/STABLE/RELEASE/g")
JAIL_NAME="organizr"    
INTERFACE="vnet0"

LOCAL_CONFIG="/mnt/Tank/configs/organizr"
JAIL_CONFIG="/mnt/config"

JAILS_FOLDER="/mnt/iocage/jails"

# Create the jail
if ! iocage create --name "${JAIL_NAME}" -p ./pkg.json -r "${RELEASE}" ip4_addr="${INTERFACE}|${JAIL_IP}/24" defaultrouter="${ROUTER}" boot="on" host_hostname="${JAIL_NAME}" vnet="on"
then
	echo "Failed to create ${JAIL_NAME}"
	exit 1
fi

# Add config folder
iocage exec "$JAIL_NAME" mkdir -p "$JAIL_CONFIG"
iocage fstab -a "$JAIL_NAME" "$LOCAL_CONFIG" "$JAIL_CONFIG" nullfs rw 0 0

# Update the php fpm config
iocage exec "$JAIL_NAME" "echo 'listen=/var/run/php-fpm.sock' >> /usr/local/etc/php-fpm.conf"
iocage exec "$JAIL_NAME" "echo 'listen.owner=www' >> /usr/local/etc/php-fpm.conf"
iocage exec "$JAIL_NAME" "echo 'listen.group=www' >> /usr/local/etc/php-fpm.conf"
iocage exec "$JAIL_NAME" "echo 'listen.mode=0660' >> /usr/local/etc/php-fpm.conf"

# Update the PHP ini
iocage exec "$JAIL_NAME" cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
iocage exec "$JAIL_NAME" sed -i '' -e 's?;date.timezone =?date.timezone = "Universal"?g' /usr/local/etc/php.ini
iocage exec "$JAIL_NAME" sed -i '' -e 's?;cgi.fix_pathinfo=1?cgi.fix_pathinfo=0?g' /usr/local/etc/php.ini

# Pull down latest source
iocage exec "$JAIL_NAME" git clone --depth 1 -b v2-develop https://github.com/causefx/Organizr /usr/local/www/Organizr

# Set permissions
iocage exec "$JAIL_NAME" chown -R www:www /usr/local/www "$JAIL_CONFIG"

# Copy site configuration
cp ./site.nginx  "$JAILS_FOLDER/$JAIL_NAME/root/usr/local/etc/nginx/nginx.conf"

# Add php and nginx to services and start up
iocage exec "$JAIL_NAME" sysrc nginx_enable=YES
iocage exec "$JAIL_NAME" sysrc php_fpm_enable=YES
iocage exec "$JAIL_NAME" service nginx start
iocage exec "$JAIL_NAME" service php-fpm start
