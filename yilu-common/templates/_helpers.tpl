{{- define "common.name" -}}
{{- .Values.serviceName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "common.containerName" -}}
{{- default ( printf "simpletrip-%s" .Values.serviceName ) .Values.containerName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
