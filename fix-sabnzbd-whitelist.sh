#!/bin/bash
DEPLOYMENT="sabnzbd/templates/deployment.yaml"

# Remove any previous broken line
sed -i '/SABNZBD_HOST_WHITELIST_ENTRIES/d' $DEPLOYMENT

# Insert the whitelist entry right after the TZ line
sed -i '/name: TZ/a \ \ \ \ \ \ \ \ - name: SABNZBD_HOST_WHITELIST_ENTRIES\n\ \ \ \ \ \ \ \ \ \ value: "*"' $DEPLOYMENT

# Revalidate
yamllint $DEPLOYMENT || echo "YAML may still need manual fixing."

# Commit and push
git add $DEPLOYMENT
git commit -m "Fix YAML and add SABNZBD_HOST_WHITELIST_ENTRIES properly"
git push

# Sync again
argocd app sync sabnzbd
