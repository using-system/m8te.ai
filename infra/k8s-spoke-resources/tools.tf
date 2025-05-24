resource "kubernetes_namespace" "tools" {
  metadata {
    name = "tools"

    labels = {
      istio-injection = "enabled"
      provisioned_by  = "terraform"
    }
  }
}

resource "kubernetes_manifest" "tools_peer_authentication" {

  manifest = {
    apiVersion = "security.istio.io/v1beta1"
    kind       = "PeerAuthentication"
    metadata = {
      name      = "default"
      namespace = kubernetes_namespace.tools.metadata[0].name
    }
    spec = {
      mtls = {
        mode = "STRICT"
      }
    }
  }
}

module "curl" {

  depends_on = [
    kubernetes_namespace.tools,
    kubernetes_manifest.tools_peer_authentication
  ]

  source = "../modules/k8s-deploy"

  name                              = "curl"
  env                               = var.env
  project_name                      = var.project_name
  namespace                         = kubernetes_namespace.tools.metadata[0].name
  workload_identity_oidc_issuer_url = data.azurerm_kubernetes_cluster.m8t.oidc_issuer_url
  environment                       = var.env

  node_selector = var.node_selector

  resource_requests = {
    cpu    = "100m"
    memory = "128Mi"
  }

  resource_limits = {
    cpu    = "300m"
    memory = "512Mi"
  }

  min_replicas = 1
  max_replicas = 1

  inject_otlp = false

  default_image = "curlimages/curl:8.13.0@sha256:e6ebb770fb6e2236c2e83ad6b6dbbd32cb6dff0b17a9482a7d4bca20f1c9b50a"
  command       = ["tail"]
  args = [
    "-f",
    "/dev/null"
  ]

  health_probe_transport_mode = "exec"

}
