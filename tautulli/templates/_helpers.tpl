{{- define "tautulli.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "tautulli.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{- define "tautulli.labels" -}}
app.kubernetes.io/name: {{ include "tautulli.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: tautulli
app.kubernetes.io/part-of: media-stack
{{- end }}

{{- define "tautulli.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tautulli.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "tautulli.chart" -}}
{{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}
