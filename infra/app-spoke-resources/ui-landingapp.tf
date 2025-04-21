module "ui_landingapp" {

  depends_on = [
    kubernetes_namespace.app,
    kubectl_manifest.otlp_app
  ]

  source = "../modules/k8s-deploy"

  name                              = "landingapp"
  namespace                         = local.k8s_namespace
  workload_identity_oidc_issuer_url = data.azurerm_kubernetes_cluster.cob.oidc_issuer_url
  environment                       = var.env

  resource_requests = {
    cpu    = var.default_cpu_request
    memory = var.default_memory_request
  }

  resource_limits = {
    cpu    = var.default_cpu_limit
    memory = var.default_memory_limit
  }

  ingress_host = "${var.host_prefix}www.${var.dns_zone_name}"
}
