resource "kubectl_manifest" "otlp_app" {

  yaml_body = <<YAML
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: otlp-app-sidecar
  namespace: ${kubernetes_namespace.app.metadata[0].name}
spec:
  mode: sidecar
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
    exporters:
      prometheusremotewrite:
        endpoint: "http://${local.prometheus_server_service}/api/v1/write"
    service:
      pipelines:
        metrics:
          receivers:
            - otlp
          processors:
            - batch
          exporters:
            - prometheusremotewrite
YAML

  ignore_fields = [
    "metadata.annotations",
    "metadata.labels",
    "metadata.finalizers",
    "status",
    "spec",
  ]
}
