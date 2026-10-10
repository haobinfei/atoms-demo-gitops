{{- define "atoms-demo.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "atoms-demo.fullname" -}}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "atoms-demo.labels" -}}
app.kubernetes.io/name: {{ include "atoms-demo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "atoms-demo.serverImage" -}}
{{- printf "%s/%s:%s" .Values.images.server.registry .Values.images.server.repository .Values.images.server.tag -}}
{{- end -}}

{{- define "atoms-demo.webImage" -}}
{{- printf "%s/%s:%s" .Values.images.web.registry .Values.images.web.repository .Values.images.web.tag -}}
{{- end -}}
