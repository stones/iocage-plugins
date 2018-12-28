echo '{"pkgs":["mono","mediainfo","sqlite3","ca_root_nss","curl"]}' > /tmp/pkg.json
iocage create -n "radarr" -p /tmp/pkg.json -r 11.1-RELEASE ip4_addr="vnet0|192.168.1.61/24" defaultrouter="192.168.1.1" vnet="on" allow_raw_sockets="1" boot="on" 
rm /tmp/pkg.json
cp ./radarr.rc  /mnt/iocage/jails/radarr/root/usr/local/etc/rc.d/radarr
iocage fstab -a lidarr /mnt/Tank/apps/radarr /config nullfs rw 0 0
iocage fstab -a lidarr /mnt/Tank/transfer/complete/movies /mnt/transfer nullfs rw 0 0
iocage fstab -a lidarr /mnt/Tank/library/audio/music /mnt/library nullfs rw 0 0
iocage exec radarr ln -s /usr/local/bin/mono /usr/bin/mono
iocage exec radarr "fetch https://github.com/Radarr/Radarr/releases/download/latest/Radarr.develop.latest.linux.tar.gz -o /usr/local/share"
iocage exec radarr "tar -xzvf /usr/local/share/Radarr.*.linux.tar.gz -C /usr/local/share"
iocage exec radarr rm /usr/local/share/Radarr.*.linux.tar.gz
iocage exec radarr chown -R media:media /usr/local/share/Radarr /config
iocage exec radarr mkdir /usr/local/etc/rc.d
