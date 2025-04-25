#!/bin/bash
yq 'select(.kind != "BackupStorageLocation" or .metadata.name != "default")' -
