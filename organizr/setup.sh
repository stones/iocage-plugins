# Create a temporary json config for iocage
echo '{"pkgs":[ "nginx","git","wget","php70","php70-curl","php70-pdo","php70-sqlite3","php70-simplexml","php70-zip","php70-openssl","curl","php70-hash","php70-json","php70-session","php70-pdo_sqlite"]}' > /tmp/pkg.json
# Create the jail
iocage create -n "organizr" -p /tmp/pkg.json -r 11.2-RELEASE ip4_addr="vnet0|192.168.1.60/24" defaultrouter="192.168.1.1" vnet="on" allow_raw_sockets="1" boot="on" 
# Remove the temporary configuration
rm /tmp/pkg.json

# Add config folder
iocage exec organizr mkdir -p /mnt/config
iocage fstab -a organizr /mnt/Tank/configs/organizr /mnt/config nullfs rw 0 0

# Update the php fpm config
iocage exec organizr echo 'listen = /var/run/php-fpm.sock' >> /usr/local/etc/php-fpm.conf
iocage exec organizr echo 'listen.owner = www' >> /usr/local/etc/php-fpm.conf
iocage exec organizr echo 'listen.group = www' >> /usr/local/etc/php-fpm.conf
iocage exec organizr echo 'listen.mode = 0660' >> /usr/local/etc/php-fpm.conf

# Update the PHP ini
iocage exec organizr cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
iocage exec organizr sed -i '' -e 's?;date.timezone =?date.timezone = "Universal"?g' /usr/local/etc/php.ini
iocage exec organizr sed -i '' -e 's?;cgi.fix_pathinfo=1?cgi.fix_pathinfo=0?g' /usr/local/etc/php.ini

# Pull down latest source
iocage exec organizr git clone -b v2-develop https://github.com/causefx/Organizr /usr/local/www/Organizr

# Set permissions
iocage exec organizr chown -R www:www /usr/local/www /mnt/config

# Copy site configuration
cp ./site.nginx  /mnt/iocage/jails/organizr/root/usr/local/etc/nginx/nginx.conf  

# Add php and nginx to services and start up
iocage exec organizr sysrc nginx_enable=YES
iocage exec organizr sysrc php_fpm_enable=YES
iocage exec organizr service nginx start
iocage exec organizr service php-fpm start

#important step Navigate to http://JailIP and set the follow the setup database location to "/config/Organizr" and Organizr for the database name. If you have an exsisting config file in the database location once you complete the setup restart the jail and login with you exsisting credentials.

# link my exsisting nginx config, you need to upload your own or edit the exsisting
# iocage exec organizr service nginx stop
# iocage exec organizr rm /usr/local/etc/nginx/nginx.conf
# iocage exec organizr ln -s /config/nginx/nginx.conf /usr/local/etc/nginx/nginx.conf
# iocage exec organizr service nginx start
