# Create jail
iocage create -n "mylar" -p ./pkg.json -r 11.2-RELEASE ip4_addr="vnet0|192.168.1.58/24" defaultrouter="192.168.1.1" vnet="on" allow_raw_sockets="1" boot="on"

# link python 
iocage exec mylar "ln -s /usr/local/bin/python2.7 /usr/local/bin/python"

# Mount folders
iocage fstab -a mylar /mnt/Tank/configs/mylar /mnt/config nullfs rw 0 0
iocage fstab -a mylar /mnt/Tank/transfer/complete/comics /mnt/transfer nullfs rw 0 0
iocage fstab -a mylar /mnt/Tank/library/print/comics /mnt/library nullfs rw 0 0

# Add media user
iocage exec mylar "pw user add media -c media -u 8675309 -d /nonexistent -s /usr/bin/nologin"

iocage exec mylar git clone https://github.com/evilhero/mylar.git /usr/local/mylar
iocage exec mylar chown -R media:media /usr/local/mylar

# Copy service file
cp ./mylar.rc  /mnt/iocage/jails/mylar/root/usr/local/etc/rc.d/mylar
iocage exec mylar chmod +x /usr/local/etc/rc.d/mylar

# Start services
iocage exec mylar sysrc mylar_enable=YES
iocage exec mylar sysrc mylar_user=media
iocage exec mylar sysrc mylar_group=media

iocage exec mylar service mylar start
