{{- define "common.name" -}}
{{- .Values.serviceName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "common.containerName" -}}
{{- default ( printf "simpletrip-%s" .Values.serviceName ) .Values.containerName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

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

{{- define "common.repository" -}}
{{- if eq .Values.amp "true" -}}
{{- .Values.image.repository -}}{{- "/amp" -}}
{{- else -}}
{{- .Values.image.repository -}}
{{- end -}}
{{- end -}}
