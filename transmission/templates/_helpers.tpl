# File: templates/_helpers.tpl
{{- define "transmission.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "transmission.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{- define "transmission.labels" -}}
app.kubernetes.io/name: {{ include "transmission.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: transmission
app.kubernetes.io/part-of: media-stack
{{- end }}

{{- define "transmission.selectorLabels" -}}
app.kubernetes.io/name: {{ include "transmission.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
