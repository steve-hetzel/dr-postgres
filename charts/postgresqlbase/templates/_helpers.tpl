{{/* vim: set filetype=mustache: */}}
{{/*
Create a default fully qualified app name.
We truncate at 24 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- printf "%s" .Release.Name | trunc 24 -}}
{{- end -}}

{{/*
Get correct image for a version of postgres, with default being the 9.2 image
*/}}
{{- define "pgimage" -}}
{{- $version := default "9.2" .Values.pgVersion -}}
{{- $matrix := dict "9.2" .Values.images.postgres92 "9.5" .Values.images.postgres95 "9.6" .Values.images.postgres96 -}}
{{- $result := index $matrix $version | default .Values.images.postgres92 -}}
{{- printf "%s" $result -}}
{{- end -}}
