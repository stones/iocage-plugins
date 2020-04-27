# [Reverse Proxy](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)

> Proxying is typically used to distribute the load among several servers, seamlessly show content from different websites, or pass requests for processing to application servers over protocols other than HTTP.

## Overview

This will use the official setup script to install _nginx_ and add 1 mount points: 

- config 

## Usage

Edit the `setup.sh` script to match your requirements ( the file is heavily commented ), then run:

`./setup.sh`

## Updating the https certificate   

`certbot certonly --manual --preferred-challenges dns --server https://acme-v02.api.letsencrypt.org/directory --manual-public-ip-logging-ok -d '*.<domain_name>' -d <domain_name>`