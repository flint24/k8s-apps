# Patch only if /mnt/velero doesn't exist
if ! kubectl get deploy -n velero velero -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[*].mountPath}' | grep -q "/mnt/velero"; then
  echo "Patching Velero to mount /mnt/velero..."
  kubectl -n velero patch deployment velero --type=json -p='[
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
else
  echo "Velero already has /mnt/velero mounted — skipping patch"
fi
