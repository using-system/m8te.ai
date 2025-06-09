locals {
  otlp_namespaces = [
    kubernetes_namespace.app.metadata[0].name,
    kubernetes_namespace.keycloak.metadata[0].name
  ]
}

resource "kubectl_manifest" "otlp" {
  for_each = toset(local.otlp_namespaces)

  yaml_body = <<YAML
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: otlp-app-sidecar
  namespace: ${each.value}
spec:
  mode: sidecar
  args:
    feature-gates: "+service.profilesSupport"
  resources:
    requests:
      cpu:    ${var.otlp.resources.requests.cpu}
      memory: ${var.otlp.resources.requests.memory}
    limits:
      cpu:    ${var.otlp.resources.limits.cpu}
      memory: ${var.otlp.resources.limits.memory}
  config:
    receivers:
      otlp:
        protocols:
          grpc: {}
    processors:
      batch: {}
      k8sattributes:
        passthrough: true
    exporters:
      prometheusremotewrite:
        endpoint: "http://${local.prometheus_server_service}/api/v1/write"
      otlphttp/loki:
        endpoint: "http://${local.loki_gateway_service}:3100/otlp"
        headers:
          X-Scope-OrgID: "default"
      otlp/tempo:
        endpoint: "http://${local.tempo_distributor_service}:4317"
        tls:
          insecure: true
        headers:
          X-Scope-OrgID: "default"
      otlp/pyroscope:
        endpoint: "${local.pyroscope_distributor_service}:4040"
        tls:
          insecure: true
        headers:
          X-Scope-OrgID: "default"
      debug:
        verbosity: detailed
    service:
      pipelines:
        metrics:
          receivers: [otlp]
          processors: [batch, k8sattributes]
          exporters: [prometheusremotewrite]
        logs:
          receivers: [otlp]
          processors: [batch, k8sattributes]
          exporters: [otlphttp/loki]
        traces:
          receivers: [otlp]
          processors: [batch, k8sattributes]
          exporters: [otlp/tempo]
        profiles:
          receivers: [otlp]
          exporters: [otlp/pyroscope]

YAML

  ignore_fields = [
    "metadata.annotations",
    "metadata.labels",
    "metadata.finalizers",
    "status",
    "spec",
  ]
}
