# [Plex Pass](https://plex.tv/)

> Your favorite web shows, podcasts, video news, recorded shows and live TV, plus your personal media, streamed to your favorite screens.  

## Overview

This will use the official setup script to install _nzbget_ and add 2 mount points: 

- config
- library

## Usage

Edit the `setup.sh` script to match your requirements ( the file is heavily commented ), then run:

`./setup.sh`

## temp

If you provide `PLEXPASS_USER` and `PLEXPASS_PASSWORD`  then it will use [PMS Updater](https://github.com/mstinaff/PMS_Updater) to update the Plex.


## Tips & tricks

If there are items in your libary that are always at the start of the "Recently added" section:

```sh
cp /mnt/config/Plex\ Media\ Server/Plug-in\ Support/Databases/com.plexapp.plugins.library.* ~/. &&
service plexmediaserver_plexpass stop && sqlite3 /mnt/config/Plex\ Media\ Server/Plug-in\ Support/Databases/com.plexapp.plugins.library.db "UPDATE metadata_items SET added_at = DATETIME('2019-04-03','+5 years') WHERE DATETIME(added_at) > DATETIME('now');" && service plexmediaserver_plexpass start && rm ~/com.plexapp.plugins.library.*
```
