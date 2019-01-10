# Create jail
iocage create -n "librarian" -p ./pkg.json -r 11.2-RELEASE ip4_addr="vnet0|192.168.1.52/24" defaultrouter="192.168.1.1" vnet="on" allow_raw_sockets="1" boot="on"

# link python 
iocage exec librarian "ln -s /usr/local/bin/python2.7 /usr/local/bin/python"

# Mount folders
iocage fstab -a librarian /mnt/Tank/configs/librarian /mnt/config nullfs rw 0 0
iocage fstab -a librarian /mnt/Tank/transfer/complete/books /mnt/transfer nullfs rw 0 0
iocage fstab -a librarian /mnt/Tank/library/print /mnt/library nullfs rw 0 0

# Add media user
iocage exec librarian "pw user add media -c media -u 8675309 -d /nonexistent -s /usr/bin/nologin"

iocage exec librarian git clone --depth 1 https://gitlab.com/LazyLibrarian/LazyLibrarian.git /usr/local/lazylibrarian
iocage exec librarian chown -R media:media /usr/local/lazylibrarian

# Copy service file
iocage exec librarian cp /usr/local/lazylibrarian/init/freebsd.initd /usr/local/etc/rc.d/lazylibrarian
iocage exec librarian chmod +x /usr/local/etc/rc.d/lazylibrarian

# Start services
iocage exec librarian sysrc lazylibrarian_enable=YES
iocage exec librarian sysrc lazylibrarian_user=media
iocage exec librarian sysrc lazylibrarian_group=media
iocage exec librarian sysrc lazylibrarian_datadir=/mnt/config

iocage exec librarian service lazylibrarian start
