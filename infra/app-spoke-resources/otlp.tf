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
      cpu:    ${var.resources.otlp.requests.cpu}
      memory: ${var.resources.otlp.requests.memory}
    limits:
      cpu:    ${var.resources.otlp.limits.cpu}
      memory: ${var.resources.otlp.limits.memory}
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
