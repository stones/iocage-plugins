RELEASE=$(freebsd-version | cut -d - -f -1)"-RELEASE"
JAILS_MOUNT=$(zfs get -H -o value mountpoint $(iocage get -p)/iocage)

echo "$JAIL_MOUNT"


# Create Jail
iocage create -n "radarr" -p ./pkg.json -r "$RELEASE" ip4_addr="vnet0|192.168.20.211/24" defaultrouter="192.168.20.1" vnet="on" allow_raw_sockets="1" boot="on"

# Update to Latest Repo
iocage exec radarr "mkdir -p /usr/local/etc/pkg/repos"
iocage exec radarr echo -e 'FreeBSD: { url: "pkg+http://pkg.FreeBSD.org/\${ABI}/latest\" }' > /usr/local/etc/pkg/repos/FreeBSD.conf

iocage exec radarr "pkg upgrade"

# Install pkgs
# iocage exec radarr pkg update && pkg upgrade


#fetch https://github.com/jailmanager/jailmanager.github.io/releases/download/v0.0.1/mono-6.8.0.105.txz
#pkg install -y mono-6.8.0.105.txz


iocage exec radarr mkdir /mnt/config
iocage exec radarr mkdir /mnt/transfer
iocage exec radarr mkdir /mnt/library

iocage fstab -a radarr /mnt/Tank/configs/radarr /mnt/config nullfs rw 0 0
iocage fstab -a radarr /mnt/Tank/transfer/complete/movies /mnt/transfer nullfs rw 0 0
iocage fstab -a radarr /mnt/Tank/library/video/movies /mnt/library nullfs rw 0 0

# Link mono
iocage exec radarr ln -s /usr/local/bin/mono /usr/bin/mono

# Download radarr
iocage exec radarr "fetch https://github.com/Radarr/Radarr/releases/download/v3.0.2.4552/Radarr.master.3.0.2.4552.linux.tar.gz -o /usr/local/share"
iocage exec radarr "tar -xzvf /usr/local/share/Radarr.master.3.0.2.4552.linux.tar.gz -C /usr/local/share"
iocage exec radarr rm /usr/local/share/Radarr.master.3.0.2.4552.linux.tar.gz

## Media Permissions
iocage exec radarr "pw user add radarr -c radarr -u 352 -d /nonexistent -s /usr/bin/nologin"

# Create users
iocage exec radarr "pw user add media -c media -u 8675309 -d /nonexistent -s /usr/bin/nologin"
iocage exec radarr "pw groupadd -n media -g 8675309"
iocage exec radarr "pw groupmod media -m radarr"
iocage exec radarr chown -R media:media /usr/local/share/Radarr /mnt/config

# Copy sysrc
iocage exec radarr mkdir -p /usr/local/etc/rc.d
cp ./radarr.rc  /mnt/Tank/iocage/jails/radarr/root/usr/local/etc/rc.d/radarr
iocage exec radarr chmod u+x /usr/local/etc/rc.d/radarr

iocage exec radarr sysrc "radarr_enable=YES"
iocage exec radarr sysrc "radarr_user=media"

iocage exec radarr service radarr start
