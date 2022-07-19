{{- define "common.name" -}}
{{- .Values.serviceName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "common.containerName" -}}
{{- default ( printf "simpletrip-%s" .Values.serviceName ) .Values.containerName | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "imageRepository" -}}
{{- default ( printf "simpletrip-%s" .Values.serviceName ) .Values.containerName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "fullname" }}
{{.Release.Name | trunc 65 }}
{{- end }}

{{/* vim: set filetype=mustache: */}}
{{/*
Renders a value that contains template.
Usage:
{{ include "common.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "common.tplvalues.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}
