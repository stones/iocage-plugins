JAIL_NAME="paperless"
JAIL_INTERFACE="vnet0"
JAIL_IP="192.168.1.60"
DEFAULT_ROUTER="192.168.1.1"

RELEASE=$(freebsd-version | sed "s/STABLE/RELEASE/g")

JAIL_FOLDER="/mnt/iocage/jails"

# Create the jail
iocage create -n "${JAIL_NAME}" -p ./pkg.json -r "${RELEASE}" ip4_addr="{$JAIL_INTERFACE}|{$JAIL_IP}/24" defaultrouter="{$DEFAULT_ROUTER}" vnet="on" allow_raw_sockets="1" boot="on" 

# Add config folder
iocage exec "{$JAIL_NAME}" mkdir -p /mnt/config
iocage fstab -a organizr /mnt/Tank/configs/organizr /mnt/config nullfs rw 0 0

# Update the php fpm config
iocage exec "{$JAIL_NAME}" "echo 'listen=/var/run/php-fpm.sock' >> /usr/local/etc/php-fpm.conf"
iocage exec "{$JAIL_NAME}" "echo 'listen.owner=www' >> /usr/local/etc/php-fpm.conf"
iocage exec "{$JAIL_NAME}" "echo 'listen.group=www' >> /usr/local/etc/php-fpm.conf"
iocage exec "{$JAIL_NAME}" "echo 'listen.mode=0660' >> /usr/local/etc/php-fpm.conf"

# Update the PHP ini
iocage exec "{$JAIL_NAME}" cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
iocage exec "{$JAIL_NAME}" sed -i '' -e 's?;date.timezone =?date.timezone = "Universal"?g' /usr/local/etc/php.ini
iocage exec "{$JAIL_NAME}" sed -i '' -e 's?;cgi.fix_pathinfo=1?cgi.fix_pathinfo=0?g' /usr/local/etc/php.ini

# Pull down latest source
iocage exec "{$JAIL_NAME}" git clone --depth 1 -b v2-develop https://github.com/causefx/Organizr /usr/local/www/Organizr

# Set permissions
iocage exec "{$JAIL_NAME}" chown -R www:www /usr/local/www /mnt/config

# Copy site configuration
cp ./site.nginx  "{$JAIL_FOLDER}/{$JAIL_NAME}/root/usr/local/etc/nginx/nginx.conf"

# Add php and nginx to services and start up
iocage exec "{$JAIL_NAME}" sysrc nginx_enable=YES
iocage exec "{$JAIL_NAME}" sysrc php_fpm_enable=YES
iocage exec "{$JAIL_NAME}" service nginx start
iocage exec "{$JAIL_NAME}" service php-fpm start
