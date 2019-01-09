# Create Jail
iocage create -n "lidarr" -p ./pkg.json -r 11.2-RELEASE ip4_addr="vnet0|192.168.1.56/24" defaultrouter="192.168.1.1" vnet="on" allow_raw_sockets="1" boot="on"

# Update to Latest Repo
iocage exec lidarr "mkdir -p /usr/local/etc/pkg/repos"
iocage exec lidarr echo -e 'FreeBSD: { url: "pkg+http://pkg.FreeBSD.org/\${ABI}/latest\" }' > /usr/local/etc/pkg/repos/FreeBSD.conf

iocage exec lidarr "pkg upgrade"

# Install pkgs
# iocage exec lidarr pkg update && pkg upgrade

iocage fstab -a lidarr /mnt/Tank/configs/lidarr /mnt/config nullfs rw 0 0
iocage fstab -a lidarr /mnt/Tank/transfer/complete/music /mnt/transfer nullfs rw 0 0
iocage fstab -a lidarr /mnt/Tank/library/audio/music /mnt/library nullfs rw 0 0

# Link mono
iocage exec lidarr ln -s /usr/local/bin/mono /usr/bin/mono

# Download lidarr
iocage exec lidarr "fetch https://github.com/lidarr/Lidarr/releases/download/v0.5.0.583/Lidarr.develop.0.5.0.583.linux.tar.gz -o /usr/local/share"
iocage exec lidarr "tar -xzvf /usr/local/share/Lidarr.develop.0.5.0.583.linux.tar.gz  -C /usr/local/share"
iocage exec lidarr rm /usr/local/share/Lidarr.develop.0.5.0.583.linux.tar.gz

## Media Permissions
iocage exec lidarr "pw user add lidarr -c lidarr -u 352 -d /nonexistent -s /usr/bin/nologin"

# Create users
iocage exec lidarr "pw user add media -c media -u 8675309 -d /nonexistent -s /usr/bin/nologin"
iocage exec lidarr "pw groupadd -n media -g 8675309"
iocage exec lidarr "pw groupmod media -m lidarr"
iocage exec lidarr chown -R media:media /usr/local/share/Lidarr /mnt/config

# Copy sysrc
iocage exec lidarr mkdir -p /usr/local/etc/rc.d
cp ./lidarr.rc  /mnt/iocage/jails/lidarr/root/usr/local/etc/rc.d/lidarr
iocage exec lidarr chmod u+x /usr/local/etc/rc.d/lidarr

iocage exec lidarr sysrc "lidarr_enable=YES"
iocage exec lidarr sysrc "lidarr_user=media"

iocage exec lidarr service lidarr start