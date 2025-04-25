#!/bin/bash

set -e

echo "🚀 K8s App Generator (Offline Mode - No Docker Needed)"

read -p "App name (e.g., radarr, lidarr): " APP_NAME
read -p "Namespace to deploy to: " NAMESPACE
read -p "PVC size for config (e.g., 1Gi): " PVC_SIZE
read -p "StorageClass for config PVC (e.g., longhorn-2replicas) [longhorn-2replicas]: " STORAGE_CLASS
STORAGE_CLASS=${STORAGE_CLASS:-longhorn-2replicas}
read -p "Base directory for app data (e.g., /mnt/Father/downloads): " BASE_DIR

# Remove trailing slashes
BASE_DIR=$(echo "$BASE_DIR" | sed 's:/*$::')

# Static image and port maps
declare -A IMAGE_MAP=(
  [radarr]="linuxserver/radarr:latest"
  [sonarr]="linuxserver/sonarr:latest"
  [lidarr]="linuxserver/lidarr:latest"
  [tautulli]="linuxserver/tautulli:latest"
  [prowlarr]="linuxserver/prowlarr:latest"
  [transmission]="linuxserver/transmission:latest"
  [nextcloud]="linuxserver/nextcloud:latest"
  [homepage]="ghcr.io/gethomepage/homepage:latest"
)

declare -A PORT_MAP=(
  [radarr]="7878"
  [sonarr]="8989"
  [lidarr]="8686"
  [tautulli]="8181"
  [prowlarr]="9696"
  [transmission]="9091"
  [nextcloud]="80"
  [homepage]="3000"
)

DEFAULT_IMAGE="${IMAGE_MAP[$APP_NAME]:-linuxserver/$APP_NAME:latest}"
DEFAULT_PORT="${PORT_MAP[$APP_NAME]:-80}"

read -p "Container image [$DEFAULT_IMAGE]: " CONTAINER_IMAGE
CONTAINER_IMAGE=${CONTAINER_IMAGE:-$DEFAULT_IMAGE}

read -p "Container port [$DEFAULT_PORT]: " CONTAINER_PORT
CONTAINER_PORT=${CONTAINER_PORT:-$DEFAULT_PORT}

# Ensure namespace exists
kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

mkdir -p "$APP_NAME/templates"

# Create values.yaml
cat <<EOF > "$APP_NAME/values.yaml"
image:
  repository: ${CONTAINER_IMAGE%:*}
  tag: ${CONTAINER_IMAGE#*:}
  pullPolicy: IfNotPresent

env:
  PUID: 1000
  PGID: 100
  TZ: Europe/Berlin

service:
  main:
    enabled: true
    type: NodePort
    ports:
      http:
        port: $CONTAINER_PORT
        nodePort: 30${CONTAINER_PORT: -3}

persistence:
  config:
    enabled: true
    mountPath: /config
    size: $PVC_SIZE
    accessMode: ReadWriteOnce
    storageClass: $STORAGE_CLASS

  data:
    enabled: true
    type: hostPath
    hostPath: $BASE_DIR
    mountPath: /data

resources: {}

podSecurityContext:
  runAsUser: 1000
  runAsGroup: 100
  fsGroup: 100

nodeSelector:
  kubernetes.io/hostname: node1
EOF

# Create deployment.yaml
cat <<EOF > "$APP_NAME/templates/deployment.yaml"
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
      nodeSelector:
        kubernetes.io/hostname: node1
      securityContext:
        fsGroup: 100
      containers:
        - name: $APP_NAME
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          env:
            - name: PUID
              value: "{{ .Values.env.PUID }}"
            - name: PGID
              value: "{{ .Values.env.PGID }}"
            - name: TZ
              value: "{{ .Values.env.TZ }}"
          ports:
            - containerPort: $CONTAINER_PORT
          volumeMounts:
            - name: config
              mountPath: /config
            - name: data
              mountPath: /data
      volumes:
        - name: config
          persistentVolumeClaim:
            claimName: ${APP_NAME}-config
        - name: data
          hostPath:
            path: $BASE_DIR
EOF

# Create pvc.yaml
cat <<EOF > "$APP_NAME/templates/pvc.yaml"
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

# Create Chart.yaml
cat <<EOF > "$APP_NAME/Chart.yaml"
apiVersion: v2
name: $APP_NAME
description: A Helm chart for $APP_NAME
version: 0.1.0
appVersion: latest
EOF

# Create _helpers.tpl
cat <<EOF > "$APP_NAME/templates/_helpers.tpl"
{{- define "$APP_NAME.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "$APP_NAME.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{- define "$APP_NAME.labels" -}}
app.kubernetes.io/name: {{ include "$APP_NAME.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: $APP_NAME
app.kubernetes.io/part-of: media-stack
{{- end }}

{{- define "$APP_NAME.selectorLabels" -}}
app.kubernetes.io/name: {{ include "$APP_NAME.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
EOF

# Create app.yaml for ArgoCD
cat <<EOF > "$APP_NAME-app.yaml"
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: $APP_NAME
  namespace: argocd
spec:
  destination:
    namespace: $NAMESPACE
    server: https://kubernetes.default.svc
  project: default
  source:
    path: $APP_NAME
    repoURL: https://github.com/flint24/k8s-apps.git
    targetRevision: main
    helm:
      skipCrds: true
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
EOF

# Git operations
git pull
rm -rf "$APP_NAME"
mv "$APP_NAME" "$APP_NAME"
git add "$APP_NAME" "$APP_NAME-app.yaml"
git commit -m "Add $APP_NAME app with config and NodePort service"
git push

# Deploy app
kubectl apply -f "$APP_NAME-app.yaml"
