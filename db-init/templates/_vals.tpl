{{- /*{{- define "db-init.password" -}}
{{- $existing := lookup "v1" "Secret" .Release.Namespace (printf "%s-keycloak-db-secret" .Release.Name) -}}
{{- if $existing -}}
{{- index $existing.data "password" | b64dec -}}
{{- else -}}
{{- randAlphaNum 32 -}}
{{- end -}}
{{- end -}}*/ -}}

{{- /*{{- define "db-init.createdSecretVal" -}}
valueFrom:
  secretKeyRef:
    name: {{ $.Release.Name }}-{{ $.Values.serviceName }}-db-secret
    key: {{ required ".Key name is required!" .Key }}
{{- end -}}*/ -}}

{{- /* Get the specified key from a secret */ -}}
{{- /*{{- define "db-init.fromSecret" -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace .SecretName -}}
{{- if not $secret -}}
{{- fail (printf "Secret %s not found in namespace %s" .SecretName .Release.Namespace) -}}
{{- end -}}
{{- $key := .SecretKey | required ".SecretKey is required!" -}}
{{- if not (hasKey $secret.data $key) -}}
{{- fail (printf "Key %s not found in secret %s" $key .SecretName) -}}
{{- end -}}
{{ index $secret.data $key | b64dec }}
{{- end -}}*/ -}}

{{- /*{{- define "db-init.secretOrString" -}}
{{- if typeIs "string" .Object -}}
{{ .Object }}
{{- else if typeIs "map[string]interface {}" .Object -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace ( get .Object "name") -}}
{{- if not $secret -}}
{{- fail (printf "Secret %s not found in namespace %s" ( get .Object "name") .Release.Namespace) -}}
{{- end -}}
{{- $key := ( get .Object "key") | required ".Key is required!" -}}
{{- if not (hasKey $secret.data $key) -}}
{{- fail (printf "Key %s not found in secret %s" $key ( get .Object "name")) -}}
{{- end -}}
{{ index $secret.data $key }}
{{- else -}}
{{- fail (printf "Invalid type for secretOrNone expected string or map[string]interface {} but got %T" .) -}}
{{- end -}}
{{- end -}} */ -}}

{{- define "db-init.secretName" -}}
{{- printf "%s-%s-db-secret" .Release.Name (required ".Values.db.user is required!" .Values.db.user) -}}
{{- end -}}