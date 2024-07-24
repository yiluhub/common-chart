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
{{- if .Values.servicePrefix -}}
{{- .Values.image.repository -}}/{{- .Values.servicePrefix -}}
{{- else -}}
{{- .Values.image.repository -}}
{{- end -}}
{{- end -}}

{{/* Compile all validation warnings into a single message and call fail. */}}
{{- define "common.validateValues" -}}
{{- $messages := list -}}
{{- $messages = append $messages (include "common.validateValues.staticSecrets" .) -}}
{{- $messages = append $messages (include "common.validateValues.awsConfig" .) -}}
{{- $messages = without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{- printf "\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}

{{/* Validate static-secrets secret-keys and transformation not used at the same time */}}
{{- define "common.validateValues.staticSecrets" -}}
{{- if (and .Values.secrets.staticSecrets.enabled (not (empty .Values.secrets.staticSecrets.secrets))) -}}
{{- range .Values.secrets.staticSecrets.secrets -}}
{{- if (and .transformation (not (empty .secretKeys))) -}}
common: secrets.staticSecrets
    `secretKeys` and `transformation` can't be used together
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Validate `aws.enabled` and dynamic secrets `aws` not enabled at the same time
both functionalities exports the same environment variables */}}
{{- define "common.validateValues.awsConfig" -}}
{{- if (and .Values.aws.enabled (and .Values.secrets.dynamicSecrets.enabled (not (empty .Values.secrets.dynamicSecrets.secrets)))) -}}
{{- range .Values.secrets.dynamicSecrets.secrets -}}
{{- if eq "aws" (toString .type) -}}
common: secrets.dynamicSecrets.aws
    `dynamicSecrets` with `aws` type and `aws` block can't be used together
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
