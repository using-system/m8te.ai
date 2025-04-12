resource "kubernetes_namespace" "gtw" {
  metadata {
    name = "envoy-gateway-system"

    labels = {
      provisioned_by = "terraform"
    }
  }
}

resource "helm_release" "gtw" {

  depends_on = [kubernetes_namespace.gtw]

  name             = "gateway-api"
  repository       = "https://charts.appscode.com/stable"
  chart            = "gateway-api"
  version          = var.gateway_api_helmchart_version
  create_namespace = false
  namespace        = kubernetes_namespace.gtw.metadata[0].name
  values = [
    <<EOF
EOF
  ]
}
