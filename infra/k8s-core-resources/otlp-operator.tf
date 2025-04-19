resource "kubernetes_namespace" "otlp" {
  metadata {
    name = "otlp"

    labels = {
      provisioned_by = "terraform"
    }
  }
}
resource "helm_release" "otel_operator" {

  depends_on = [helm_release.cert_manager]

  name             = "opentelemetry-operator"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-operator"
  namespace        = kubernetes_namespace.otlp.metadata[0].name
  create_namespace = false
  version          = var.otlp_operator_helmchart_version

  values = [
    <<EOF
manager:
  collectorImage:
    repository: otel/opentelemetry-collector-contrib
EOF
  ]
}
