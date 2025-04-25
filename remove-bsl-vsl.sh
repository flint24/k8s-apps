#!/bin/bash
yq 'select(.kind != "BackupStorageLocation" and .kind != "VolumeSnapshotLocation")' - > /dev/stdout
