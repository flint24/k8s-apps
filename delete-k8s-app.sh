#!/bin/bash

set -e

APP_NAME="$1"
if [ -z "$APP_NAME" ]; then
  read -p "Enter the name of the app to delete: " APP_NAME
fi

NAMESPACE="$2"
if [ -z "$NAMESPACE" ]; then
  read -p "Enter the namespace (default is 'media'): " NAMESPACE
  NAMESPACE=${NAMESPACE:-media}
fi

echo "Deleting ArgoCD app..."
argocd app delete "$APP_NAME" --yes || echo "App not found in ArgoCD."

echo "Deleting Kubernetes resources..."
kubectl delete all,cm,secret,svc,pvc -l app.kubernetes.io/name="$APP_NAME" -n "$NAMESPACE" --ignore-not-found

echo "Deleting PVCs directly (if any)..."
kubectl delete pvc -l app.kubernetes.io/name="$APP_NAME" -n "$NAMESPACE" --ignore-not-found

echo "Removing local files..."
rm -rf "$APP_NAME" "${APP_NAME}-app.yaml"

echo "Committing deletion to Git..."
git rm -rf "$APP_NAME" "${APP_NAME}-app.yaml" || true
git commit -am "Remove $APP_NAME Helm chart and app manifest"
git push

echo "Cleanup complete for $APP_NAME."
