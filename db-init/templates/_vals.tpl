{{- define "db-init.secretName" -}}
{{- printf "%s-%s-db-secret" .Release.Name (required ".Values.db.user is required!" .Values.db.user) -}}
{{- end -}}