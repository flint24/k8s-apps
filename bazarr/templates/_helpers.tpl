{{- define "bazarr.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "bazarr.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{-  := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s"  | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}
