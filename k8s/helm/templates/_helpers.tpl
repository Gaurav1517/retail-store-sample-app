{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "retail-store.name" -}}
{{- default "retail-store" .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "retail-store.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "retail-store" .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "retail-store.chart" -}}
{{- printf "%s-%s" "retail-store" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "retail-store.labels" -}}
helm.sh/chart: {{ include "retail-store.chart" . }}
{{ include "retail-store.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "retail-store.selectorLabels" -}}
app.kubernetes.io/name: {{ include "retail-store.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the namespace
*/}}
{{- define "retail-store.namespace" -}}
{{- default .Release.Namespace .Values.namespace.name }}
{{- end }}

{{/*
Service-specific labels
*/}}
{{- define "retail-store.ui.labels" -}}
{{ include "retail-store.labels" . }}
app.kubernetes.io/component: ui
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{- define "retail-store.ui.selectorLabels" -}}
{{ include "retail-store.selectorLabels" . }}
app.kubernetes.io/component: ui
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{- define "retail-store.catalog.labels" -}}
{{ include "retail-store.labels" . }}
app.kubernetes.io/component: catalog
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{- define "retail-store.catalog.selectorLabels" -}}
{{ include "retail-store.selectorLabels" . }}
app.kubernetes.io/component: catalog
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{- define "retail-store.cart.labels" -}}
{{ include "retail-store.labels" . }}
app.kubernetes.io/component: cart
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{- define "retail-store.cart.selectorLabels" -}}
{{ include "retail-store.selectorLabels" . }}
app.kubernetes.io/component: cart
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{- define "retail-store.checkout.labels" -}}
{{ include "retail-store.labels" . }}
app.kubernetes.io/component: checkout
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{- define "retail-store.checkout.selectorLabels" -}}
{{ include "retail-store.selectorLabels" . }}
app.kubernetes.io/component: checkout
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{- define "retail-store.orders.labels" -}}
{{ include "retail-store.labels" . }}
app.kubernetes.io/component: orders
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{- define "retail-store.orders.selectorLabels" -}}
{{ include "retail-store.selectorLabels" . }}
app.kubernetes.io/component: orders
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{/*
Database-related labels
*/}}
{{- define "retail-store.mysql.labels" -}}
{{ include "retail-store.labels" . }}
app.kubernetes.io/component: mysql
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{- define "retail-store.mysql.selectorLabels" -}}
{{ include "retail-store.selectorLabels" . }}
app.kubernetes.io/component: mysql
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{- define "retail-store.dynamodb.labels" -}}
{{ include "retail-store.labels" . }}
app.kubernetes.io/component: dynamodb
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{- define "retail-store.dynamodb.selectorLabels" -}}
{{ include "retail-store.selectorLabels" . }}
app.kubernetes.io/component: dynamodb
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{- define "retail-store.redis.labels" -}}
{{ include "retail-store.labels" . }}
app.kubernetes.io/component: redis
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{- define "retail-store.redis.selectorLabels" -}}
{{ include "retail-store.selectorLabels" . }}
app.kubernetes.io/component: redis
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{- define "retail-store.postgresql.labels" -}}
{{ include "retail-store.labels" . }}
app.kubernetes.io/component: postgresql
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{- define "retail-store.postgresql.selectorLabels" -}}
{{ include "retail-store.selectorLabels" . }}
app.kubernetes.io/component: postgresql
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{- define "retail-store.rabbitmq.labels" -}}
{{ include "retail-store.labels" . }}
app.kubernetes.io/component: rabbitmq
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{- define "retail-store.rabbitmq.selectorLabels" -}}
{{ include "retail-store.selectorLabels" . }}
app.kubernetes.io/component: rabbitmq
app.kubernetes.io/owner: retail-store-sample
{{- end }}

{{/*
Password generation helper
*/}}
{{- define "getOrGeneratePass" }}
{{- $len := (default 16 .Length) | int -}}
{{- $obj := (lookup "v1" .Kind .Namespace .Name).data -}}
{{- if $obj }}
{{- index $obj .Key -}}
{{- else if (eq (lower .Kind) "secret") -}}
{{- randAlphaNum $len | b64enc -}}
{{- else -}}
{{- randAlphaNum $len -}}
{{- end -}}
{{- end }}
