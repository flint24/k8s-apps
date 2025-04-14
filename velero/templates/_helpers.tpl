{{- define "velero.labels" -}}
app.kubernetes.io/name: velero
app.kubernetes.io/instance: velero
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: Helm
{{- end }}
