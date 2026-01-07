{{- define "my-argo-cd.secrets.githubAppData" -}}
githubAppID: {{ .id | quote }}
githubAppInstallationID: {{ .installationId | quote }}
githubAppPrivateKey: |
{{ .privateKey | indent  2 }}
githubAppEnterpriseBaseUrl: {{ .enterpriseBaseUrl }}
{{- end -}}

{{- define "my-argo-cd.secrets.githubAppDataEncoded" -}}
githubAppID: {{ .id | b64enc }}
githubAppInstallationID: {{ .installationId | b64enc }}
githubAppPrivateKey: |
{{ .privateKey | b64enc | indent 2 }}
githubAppEnterpriseBaseUrl: {{ .enterpriseBaseUrl | b64enc }}
{{- end -}}

{{- define "my-argo-cd.b64enc" -}}
{{- range $key, $value := . -}}
{{ $key }}: {{ $value | b64enc }}
{{ end -}}
{{- end -}}