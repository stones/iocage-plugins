# Create jail
iocage create -n "headphones" -p ./pkg.json -r 11.2-RELEASE ip4_addr="vnet0|10.0.0.40/24" defaultrouter="10.0.0.138" vnet="on" allow_raw_sockets="1" boot="on"

# link python 
iocage exec headphones "ln -s /usr/local/bin/python2.7 /usr/local/bin/python"

# Mount folders
iocage fstab -a headphones /mnt/Tank/configs/headphones /mnt/config nullfs rw 0 0
iocage fstab -a headphones /mnt/Tank/transfer/complete/music /mnt/transfer nullfs rw 0 0
iocage fstab -a headphones /mnt/Tank/library/audio/music /mnt/library nullfs rw 0 0

# Add media user
iocage exec headphones "pw user add media -c media -u 8675309 -d /nonexistent -s /usr/bin/nologin"

iocage exec headphones git clone git://github.com/rembo10/headphones.git /usr/local/headphones
iocage exec headphones chown -R media:media /usr/local/headphones

# Copy service file
cp ./headphones.rc  /mnt/Tank/iocage/jails/headphones/root/usr/local/etc/rc.d/headphones
iocage exec headphones chmod +x /usr/local/etc/rc.d/headphones

# Start services
iocage exec headphones sysrc headphones_enable=YES
iocage exec headphones sysrc headphones_user=media
iocage exec headphones sysrc headphones_group=media

iocage exec headphones service headphones start
