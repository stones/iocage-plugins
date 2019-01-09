iocage create -n "tautulli" -p ./pkg.json -r 11.2-RELEASE ip4_addr="vnet0|192.168.1.53/24" defaultrouter="192.168.1.1" vnet="on" allow_raw_sockets="1" boot="on"
iocage fstab -a tautulli /mnt/Tank/configs/tautulli /mnt/config nullfs rw 0 0
iocage exec tautulli git clone https://github.com/Tautulli/Tautulli.git /usr/local/share/Tautulli
iocage exec tautulli "pw user add tautulli -c tautulli -u 109 -d /nonexistent -s /usr/bin/nologin"
iocage exec tautulli chown -R tautulli:tautulli /usr/local/share/Tautulli /mnt/config
iocage exec tautulli cp /usr/local/share/Tautulli/init-scripts/init.freenas /usr/local/etc/rc.d/tautulli
iocage exec tautulli chmod u+x /usr/local/etc/rc.d/tautulli
iocage exec tautulli sysrc "tautulli_enable=YES"
iocage exec tautulli sysrc "tautulli_flags=--datadir /mnt/config"
iocage exec tautulli service tautulli start
