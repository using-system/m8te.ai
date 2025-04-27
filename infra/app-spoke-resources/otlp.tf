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
      k8sattributes:
        auth_type: "serviceAccount"
        passthrough: false
        extract:
          metadata:
            - k8s.namespace.name
            - k8s.pod.name
            - k8s.pod.uid
            - k8s.node.name
            - k8s.deployment.name
            - k8s.pod.start_time
    exporters:
      prometheusremotewrite:
        endpoint: "http://${local.prometheus_server_service}/api/v1/write"
      otlphttp/loki:
        endpoint: "http://${local.loki_gateway_service}:3100/otlp"
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
YAML

  ignore_fields = [
    "metadata.annotations",
    "metadata.labels",
    "metadata.finalizers",
    "status",
    "spec",
  ]
}
