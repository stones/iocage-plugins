# Create jail
iocage create -n "sonarr" -p ./pkg.json -r 11.2-RELEASE ip4_addr="vnet0|10.0.0.39/24" defaultrouter="10.0.0.138" vnet="on" allow_raw_sockets="1" boot="on"

# Add media user
iocage exec sonarr "pw user add media -c media -u 8675309 -d /nonexistent -s /usr/bin/nologin"
iocage exec sonarr "pw groupadd -n media -g 8675309"
iocage exec sonarr "pw groupmod media -m sonarr"

iocage exec sonarr mkdir /usr/local/etc/rc.d
cp ./sonarr.rc  /mnt/Tank/iocage/jails/sonarr/root/usr/local/etc/rc.d/sonarr
iocage exec sonarr chmod 555 /usr/local/etc/rc.d/sonarr

# Mount folders
iocage fstab -a sonarr /mnt/Tank/configs/sonarr /mnt/config nullfs rw 0 0
iocage fstab -a sonarr /mnt/Tank/transfer/complete/television /mnt/transfer nullfs rw 0 0
iocage fstab -a sonarr /mnt/Tank/library/video/television /mnt/library nullfs rw 0 0

iocage exec sonarr ln -s /usr/local/bin/mono /usr/bin/mono

# Install sonarr
iocage exec sonarr "fetch http://download.sonarr.tv/v2/master/mono/NzbDrone.master.tar.gz -o /usr/local/share"
iocage exec sonarr "tar -xzvf /usr/local/share/NzbDrone.master.tar.gz -C /usr/local/share"
iocage exec sonarr rm /usr/local/share/NzbDrone.master.tar.gz

iocage exec sonarr chown -R media:media /usr/local/share/NzbDrone /mnt/config

# Initialise the service
iocage exec sonarr sysrc "sonarr_enable=YES"
iocage exec sonarr service sonarr start
