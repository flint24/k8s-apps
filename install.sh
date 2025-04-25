#!/bin/bash
set -e

echo "🚀 K8s App Generator with Auto Volume Detection"

read -p "App name (e.g., radarr, lidarr): " APP_NAME
read -p "Namespace to deploy to: " NAMESPACE
read -p "PVC size for config (e.g., 1Gi): " PVC_SIZE
read -p "StorageClass for config PVC (default: longhorn-2replicas): " STORAGE_CLASS
STORAGE_CLASS=${STORAGE_CLASS:-longhorn-2replicas}

# Attempt to detect image
IMAGE_CANDIDATE=$(skopeo list-tags docker://docker.io/linuxserver/$APP_NAME 2>/dev/null | jq -r '.Tags[]?' | sort -V | tail -1)
DEFAULT_IMAGE="linuxserver/${APP_NAME}:${IMAGE_CANDIDATE:-latest}"
read -p "Container image [$DEFAULT_IMAGE]: " USER_IMAGE
CONTAINER_IMAGE=${USER_IMAGE:-$DEFAULT_IMAGE}

read -p "Container port (e.g., 3000, 8686, etc.): " CONTAINER_PORT

# Prompt for each volume (dynamic detection can be expanded later)
VOLUMES=(config)

mkdir -p "$APP_NAME/templates"

# Generate deployment.yaml
cat <<EOF > $APP_NAME/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $APP_NAME
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: $APP_NAME
  template:
    metadata:
      labels:
        app.kubernetes.io/name: $APP_NAME
    spec:
      containers:
        - name: $APP_NAME
          image: "$CONTAINER_IMAGE"
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: $CONTAINER_PORT
          volumeMounts:
EOF

for VOL in "${VOLUMES[@]}"; do
  echo "            - name: $VOL" >> $APP_NAME/templates/deployment.yaml
  echo "              mountPath: /$VOL" >> $APP_NAME/templates/deployment.yaml
done

cat <<EOF >> $APP_NAME/templates/deployment.yaml
      volumes:
EOF

for VOL in "${VOLUMES[@]}"; do
  if [[ "$VOL" == "config" ]]; then
    cat <<EOF >> $APP_NAME/templates/deployment.yaml
        - name: $VOL
          persistentVolumeClaim:
            claimName: ${APP_NAME}-${VOL}
EOF
  else
    echo "Where should $VOL be stored? (e.g., /mnt/Father/downloads/$APP_NAME/$VOL or type 'longhorn')"
    read -p "Storage path for $VOL: " VOL_PATH
    if [[ "$VOL_PATH" == "longhorn" ]]; then
      cat <<EOF >> $APP_NAME/templates/deployment.yaml
        - name: $VOL
          persistentVolumeClaim:
            claimName: ${APP_NAME}-${VOL}
EOF
    else
      mkdir -p "$VOL_PATH"
      cat <<EOF >> $APP_NAME/templates/deployment.yaml
        - name: $VOL
          hostPath:
            path: $VOL_PATH
EOF
    fi
  fi
  echo >> $APP_NAME/templates/deployment.yaml
done

# Generate pvc.yaml
cat <<EOF > $APP_NAME/templates/pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${APP_NAME}-config
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: $PVC_SIZE
  storageClassName: $STORAGE_CLASS
EOF

# Generate service.yaml
cat <<EOF > $APP_NAME/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: $APP_NAME
spec:
  selector:
    app.kubernetes.io/name: $APP_NAME
  type: NodePort
  ports:
    - port: $CONTAINER_PORT
      targetPort: $CONTAINER_PORT
      nodePort: $((30000 + RANDOM % 1000))
EOF

# Generate values.yaml
cat <<EOF > $APP_NAME/values.yaml
image:
  repository: $CONTAINER_IMAGE
  pullPolicy: IfNotPresent
  tag: ""
EOF

# Generate Chart.yaml
cat <<EOF > $APP_NAME/Chart.yaml
apiVersion: v2
name: $APP_NAME
description: Helm chart for $APP_NAME
type: application
version: 0.1.0
appVersion: "latest"
EOF

# Generate app manifest for ArgoCD
cat <<EOF > ${APP_NAME}-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: $APP_NAME
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/flint24/k8s-apps.git
    targetRevision: main
    path: $APP_NAME
  destination:
    server: https://kubernetes.default.svc
    namespace: $NAMESPACE
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

# Git push
git add $APP_NAME ${APP_NAME}-app.yaml
git commit -m "Add $APP_NAME app with detected volumes"
git push

# Create namespace if missing
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create ns $NAMESPACE

# Apply ArgoCD app
kubectl apply -f ${APP_NAME}-app.yaml

echo "✅ Done! $APP_NAME deployed to ArgoCD in namespace '$NAMESPACE'"
