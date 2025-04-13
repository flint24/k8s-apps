{{- define "bazarr.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "bazarr.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{- define "bazarr.labels" -}}
app.kubernetes.io/name: {{ include "bazarr.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: bazarr
app.kubernetes.io/part-of: media-stack
{{- end }}

{{- define "bazarr.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bazarr.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
