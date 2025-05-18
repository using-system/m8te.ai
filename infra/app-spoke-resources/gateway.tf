module "gateway" {

  depends_on = [
    kubernetes_namespace.app,
    kubectl_manifest.otlp_app
  ]

  source = "../modules/k8s-deploy"

  name                              = "m8t-gateway"
  env                               = var.env
  project_name                      = var.project_name
  namespace                         = local.k8s_namespace
  workload_identity_oidc_issuer_url = data.azurerm_kubernetes_cluster.m8t.oidc_issuer_url
  environment                       = var.env

  resource_requests = var.resources.gateway.requests
  resource_limits   = var.resources.gateway.limits

  run_as_user  = local.dotnet_user_uid
  run_as_group = local.dotnet_user_uid

  ingress_host = "${var.host_prefix}api.${var.dns_zone_name}"
}
