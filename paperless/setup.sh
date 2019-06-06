DEFAULT_ROUTER="192.168.1.1"
JAIL_FOLDER="/mnt/iocage/jails"
JAIL_INTERFACE="vnet0"
JAIL_IP="192.168.1.61"
JAIL_NAME="paperless"
RELEASE=$(freebsd-version | sed "s/STABLE/RELEASE/g")

# Create the jail
iocage create -n "$JAIL_NAME" -p ./pkg.json -r "${RELEASE}" ip4_addr="$JAIL_INTERFACE|$JAIL_IP/24" defaultrouter="$DEFAULT_ROUTER" vnet="on" allow_raw_sockets="1" boot="on" 

# Add config folder
iocage exec "$JAIL_NAME" mkdir -p /mnt/config
iocage fstab -a "$JAIL_NAME" /mnt/Tank/configs/paperless /mnt/config nullfs rw 0 0

mkdir -p $JAIL_FOLDER/root/usr/local/www

# Pull down latest source
iocage exec "$JAIL_NAME" git clone --depth 1 git clone https://github.com/the-paperless-project/paperless.git /usr/local/www/paperless

iocage exec "$JAIL_NAME" cp /usr/local/www/paperless/paperless.conf.example /etc/paperless.conf

# Update the config
iocage exec "$JAIL_NAME" sed -i '' -e 's?PAPERLESS_CONSUMPTION_DIR=""?PAPERLESS_CONSUMPTION_DIR=/mnt/config/consumption?g' /etc/paperless.conf
iocage exec "$JAIL_NAME" sed -i '' -e 's?#PAPERLESS_DBDIR=/path/to/database/file?PAPERLESS_DBDIR=/mnt/config/db?g' /etc/paperless.conf
iocage exec "$JAIL_NAME" sed -i '' -e 's?#PAPERLESS_MEDIADIR=/path/to/media?PAPERLESS_MEDIADIR=/mnt/config/media?g' /etc/paperless.conf

# Set permissions
iocage exec "$JAIL_NAME" chown -R www:www /usr/local/www /mnt/config

iocage exec "$JAIL_NAME" ln -s /usr/local/bin/python3 /usr/local/bin/python

# Install dependencies
iocage exec "$JAIL_NAME" pip-3.6 install --upgrade pip
iocage exec "$JAIL_NAME" pip install --requirement /usr/local/www/paperless/requirements.txt

iocage exec "$JAIL_NAME" /usr/local/www/paperless/src/manage.py migrate

cp ./paperless.rc  "/mnt/iocage/jails/$JAIL_NAME/root/etc/rc.d/paperless"
# Copy site configuration
cp ./site.nginx  "$JAIL_FOLDER/$JAIL_NAME/root/usr/local/etc/nginx/nginx.conf"

# Add php and nginx to services and start up
iocage exec "$JAIL_NAME" sysrc nginx_enable=YES
iocage exec "$JAIL_NAME" service nginx start

iocage exec "$JAIL_NAME" sysrc paperless_enable=YES
iocage exec "$JAIL_NAME" service paperless start
iocage restart "$JAIL_NAME"