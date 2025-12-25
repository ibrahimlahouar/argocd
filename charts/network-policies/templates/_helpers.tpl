{{/*
Network Policies Helpers
========================
*/}}

{{/*
Nom complet du chart
*/}}
{{- define "network-policies.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Labels communs
*/}}
{{- define "network-policies.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: data-platform
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

