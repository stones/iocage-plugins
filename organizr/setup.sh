# Create the jail
iocage create -n "organizr" -p ./pkg.json -r 11.2-RELEASE ip4_addr="vnet0|192.168.1.60/24" defaultrouter="192.168.1.1" vnet="on" allow_raw_sockets="1" boot="on" 

# Add config folder
iocage exec organizr mkdir -p /mnt/config
iocage fstab -a organizr /mnt/Tank/configs/organizr /mnt/config nullfs rw 0 0

# Update the php fpm config
iocage exec organizr "echo 'listen=/var/run/php-fpm.sock' >> /usr/local/etc/php-fpm.conf"
iocage exec organizr "echo 'listen.owner=www' >> /usr/local/etc/php-fpm.conf"
iocage exec organizr "echo 'listen.group=www' >> /usr/local/etc/php-fpm.conf"
iocage exec organizr "echo 'listen.mode=0660' >> /usr/local/etc/php-fpm.conf"

# Update the PHP ini
iocage exec organizr cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
iocage exec organizr sed -i '' -e 's?;date.timezone =?date.timezone = "Universal"?g' /usr/local/etc/php.ini
iocage exec organizr sed -i '' -e 's?;cgi.fix_pathinfo=1?cgi.fix_pathinfo=0?g' /usr/local/etc/php.ini

# Pull down latest source
iocage exec organizr git clone --depth 1 -b v2-develop https://github.com/causefx/Organizr /usr/local/www/Organizr

# Set permissions
iocage exec organizr chown -R www:www /usr/local/www /mnt/config

# Copy site configuration
cp ./site.nginx  /mnt/iocage/jails/organizr/root/usr/local/etc/nginx/nginx.conf  

# Add php and nginx to services and start up
iocage exec organizr sysrc nginx_enable=YES
iocage exec organizr sysrc php_fpm_enable=YES
iocage exec organizr service nginx start
iocage exec organizr service php-fpm start
