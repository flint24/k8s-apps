#!/bin/bash

kubectl -n velero patch deployment velero \
  --type=json \
  -p='[
    {
      "op": "add",
      "path": "/spec/template/spec/volumes/-",
      "value": {
        "name": "velero-backup",
        "persistentVolumeClaim": {
          "claimName": "velero-backup-pvc"
        }
      }
    },
    {
      "op": "add",
      "path": "/spec/template/spec/containers/0/volumeMounts/-",
      "value": {
        "name": "velero-backup",
        "mountPath": "/mnt/velero"
      }
    }
  ]'
