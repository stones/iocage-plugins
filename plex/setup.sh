#Create the jail
iocage create -n "plex" -p ./pkg.json -r 11.2-RELEASE ip4_addr="vnet0|192.168.1.50/24" defaultrouter="192.168.1.1" vnet="on" allow_raw_sockets="1" boot="on"

# Add media user
iocage exec plex "pw user add media -c media -u 8675309 -d /nonexistent -s /usr/bin/nologin"
iocage exec plex "pw groupmod media -m plex"

# Set updates to be more frequent
iocage exec plex "mkdir -p /usr/local/etc/pkg/repos"
iocage exec plex echo -e 'FreeBSD: { url: "pkg+http://pkg.FreeBSD.org/\${ABI}/latest\" }' > /usr/local/etc/pkg/repos/FreeBSD.conf

iocage exec plex "pkg upgrade"

# Mount volumes
iocage fstab -a plex /mnt/Tank/configs/plex /mnt/config nullfs rw 0 0
iocage fstab -a plex /mnt/Tank/library/audio /mnt/audio nullfs rw 0 0
iocage fstab -a plex /mnt/Tank/library/video /mnt/video nullfs rw 0 0
iocage fstab -a plex /mnt/Tank/library/images /mnt/images nullfs rw 0 0

# Change permissions
iocage exec plex chown -R media:media /mnt/config

# Enable plex on start
iocage exec plex sysrc "plexmediaserver_plexpass_enable=YES"
iocage exec plex sysrc plexmediaserver_plexpass_support_path="/mnt/config"
iocage exec plex sysrc plexmediaserver_plexpass_user="media"
iocage exec plex service plexmediaserver_plexpass start

# Copy updater files
# cp ./updater.sh  /mnt/iocage/jails/plex/root/
# cp ./creds.txt  /mnt/iocage/jails/plex/root/

iocage restart plex
