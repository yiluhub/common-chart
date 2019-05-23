{{- define "common.name" -}}
{{- default .Values.serviceName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "common.simpletripName" -}}
{{- printf "simpletrip-%s" .Values.serviceName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
