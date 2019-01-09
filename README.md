# IOcage Plugin Scripts

> These are not supposed to be used without customisation. Please don't use blindly

## Overview

A set of scripts to ease creation of jails so I can quickly upgrade other people's systems.

These were shamelessly taken and adapted from [FN11.2 iocage jails - Plex, Tautulli, Sonarr, Radarr, Lidarr, Jackett, Transmission, Organizr](https://forums.freenas.org/index.php?resources/fn11-2-iocage-jails-plex-tautulli-sonarr-radarr-lidarr-jackett-transmission-organizr.58/) and this [gist](https://gist.github.com/mow4cash/e2fd4991bd2b787ca407a355d134b0ff), but all that copying and pasting got to me.

The main benefit of these over the default plugins is that the configurations are mounted separately so if for some reason you need to re-install, you don't have to reconfigure everything

## Note
Probably the main thing you will want to change is the IP address and the default router as they need to match you router
eg:
```
ip4_addr="vnet0|192.168.1.52/24" defaultrouter="192.168.1.1"
```

## Plugins

- [Flex](./plex/README.md)
- [Headphones](./headphones/README.md)
- [NZBGet](./nzbget/README.md)
- [Organizr](./organizr/README.md)
- [Plex](./plex/README.md)
- [Sonarr](./sonarr/README.md)