#!/bin/bash

## mkdir webroot:
mkdir -p ${webroot}

## Copy source to webroot:
gsutil cp -r gs://${source_bucket}/* ${webroot}

## Chown:
if [ -n "${webroot}" ]; then
  chown www-data:www-data -R ${webroot}
fi

## Restart nginx:
systemctl restart nginx
