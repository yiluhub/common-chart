{{- define "common.name" -}}
{{- default .Values.serviceName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "common.containerName" -}}
{{- default .Values.containerName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
