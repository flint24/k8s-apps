#!/bin/bash

DEPLOYMENT="sabnzbd/templates/deployment.yaml"

# Backup the original just in case
cp $DEPLOYMENT $DEPLOYMENT.bak

# Remove previous broken line
sed -i '/SABNZBD_HOST_WHITELIST_ENTRIES/d' $DEPLOYMENT

# Append correct env var after TZ
awk '
  /- name: TZ/ {
    print;
    print "            - name: SABNZBD_HOST_WHITELIST_ENTRIES";
    print "              value: \"*\"";
    next;
  }
  { print }
' $DEPLOYMENT > tmp.yaml && mv tmp.yaml $DEPLOYMENT

# Git commit & sync
git add $DEPLOYMENT
git commit -m "Fix YAML syntax and add SABNZBD_HOST_WHITELIST_ENTRIES properly"
git push

argocd app sync sabnzbd
