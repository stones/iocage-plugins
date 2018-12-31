# Create the jail
iocage create -n "phlex" -p ./pkg.json -r 11.2-RELEASE ip4_addr="vnet0|192.168.1.62/24" defaultrouter="192.168.1.1" vnet="on" allow_raw_sockets="1" boot="on" 

# Update the php fpm config
iocage exec phlex "echo 'listen=/var/run/php-fpm.sock' >> /usr/local/etc/php-fpm.conf"
iocage exec phlex "echo 'listen.owner=www' >> /usr/local/etc/php-fpm.conf"
iocage exec phlex "echo 'listen.group=www' >> /usr/local/etc/php-fpm.conf"
iocage exec phlex "echo 'listen.mode=0660' >> /usr/local/etc/php-fpm.conf"

# Update the PHP ini
iocage exec phlex cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
iocage exec phlex sed -i '' -e 's?;date.timezone =?date.timezone = "Universal"?g' /usr/local/etc/php.ini
iocage exec phlex sed -i '' -e 's?;cgi.fix_pathinfo=1?cgi.fix_pathinfo=0?g' /usr/local/etc/php.ini

# Pull down latest source
iocage exec phlex git clone https://github.com/d8ahazard/Phlex.git /usr/local/www/phlex --depth 1

# Set permissions
iocage exec phlex chown -R www:www /usr/local/www 

# Copy site configuration
cp ./site.nginx  /mnt/iocage/jails/phlex/root/usr/local/etc/nginx/nginx.conf  

# Add php and nginx to services and start up
iocage exec phlex sysrc nginx_enable=YES
iocage exec phlex sysrc php_fpm_enable=YES
iocage exec phlex service nginx start
iocage exec phlex service php-fpm start
