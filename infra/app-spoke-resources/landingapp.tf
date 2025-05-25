module "landingapp" {

  depends_on = [
    kubernetes_namespace.app,
    kubectl_manifest.otlp_app
  ]

  source = "../modules/k8s-deploy"

  name                              = "m8t-landing-app"
  env                               = var.env
  project_name                      = var.project_name
  namespace                         = local.k8s_namespace
  workload_identity_oidc_issuer_url = data.azurerm_kubernetes_cluster.m8t.oidc_issuer_url
  environment                       = var.env

  node_selector = var.node_selector

  resource_requests = var.resources.landingapp.requests
  resource_limits   = var.resources.landingapp.limits

  ingress_host = "${var.host_prefix}www.${var.dns_zone_name}"
}
