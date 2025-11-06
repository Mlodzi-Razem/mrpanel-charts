{{ define "mrpanel.infra.postgres.service.labels" -}}
component: postgres
exposed: cluster
{{- end }}

{{ define "mrpanel.infra.secret.name" -}}
{{ .Release.Name }}-secret
{{- end }}

{{ define "mrpanel.infra.postgres.scripts.configmap.name" -}}
{{ .Release.Name }}-scripts-configmap
{{- end }}

{{ define "mrpanel.infra.postgres.volume.claim.name" -}}
postgres-{{ . }}-claim
{{- end }}