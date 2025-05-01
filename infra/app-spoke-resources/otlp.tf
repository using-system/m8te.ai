resource "kubectl_manifest" "otlp_app" {

  yaml_body = <<YAML
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: otlp-app-sidecar
  namespace: ${kubernetes_namespace.app.metadata[0].name}
spec:
  mode: sidecar
  args:
    feature-gates: "+service.profilesSupport"
  resources:
    requests:
      cpu:    ${var.default_cpu_request}
      memory: ${var.default_memory_request}
    limits:
      cpu:    ${var.default_cpu_limit}
      memory: ${var.default_memory_limit}
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
      otlphttp/tempo:
        endpoint: "http://${local.tempo_gateway_service}"
        headers:
          X-Scope-OrgID: "default"
      otlp/pyroscope:
        endpoint: "${local.pyroscope_distributor_service}:4040"
        tls:
          insecure: true
        headers:
          X-Scope-OrgID: "default"
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
          exporters: [otlphttp/tempo]
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
