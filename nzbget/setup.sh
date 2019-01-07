# Create the jail
iocage create -n "nzbget" -p ./pkg.json -r 11.2-RELEASE ip4_addr="vnet0|192.168.1.57/24" defaultrouter="192.168.1.1" vnet="on" allow_raw_sockets="1" boot="on" 
# Add media user
iocage exec nzbget "pw user add media -c media -u 8675309 -d /nonexistent -s /usr/bin/nologin"
iocage exec nzbget "pw groupadd -n media -g 8675309"
iocage exec nzbget "pw groupmod media -m nzbget"
# Ensure the rc.d folder exists
iocage exec nzbget mkdir -p /usr/local/etc/rc.d
# Copy the nzbget file so we can use 'service nzbget start|stop|etc'
cp ./nzbget.rc  /mnt/iocage/jails/nzbget/root/etc/rc.d/nzbget
# Set permissions
iocage exec nzbget chmod 555 /etc/rc.d/nzbget
# Mount volumes
iocage fstab -a nzbget /mnt/Tank/transfer /mnt/transfer nullfs rw 0 0
iocage fstab -a nzbget /mnt/Tank/configs/nzbget /mnt/config nullfs rw 0 0
# Download nzbget install script
iocage exec nzbget "fetch https://nzbget.net/download/nzbget-latest-bin-freebsd.run"
# install nzbget
iocage exec nzbget "sh nzbget-latest-bin-freebsd.run --destdir /usr/local/share/nzbget"
# remove install script
iocage exec nzbget rm nzbget-latest-bin-freebsd.run 
# Set permissions on mounted folders 
iocage exec nzbget chown -R media:media /mnt/transfer /mnt/config /usr/local/share/nzbget
# Enable nzbget
iocage exec nzbget sysrc "nzbget_user=media"
iocage exec nzbget sysrc "nzbget_enable=YES"
# Restart the jail
iocage restart nzbget