module "components" {
  for_each = var.components

  depends_on = [
    kubernetes_namespace.app,
    kubectl_manifest.otlp
  ]

  source = "../modules/k8s-deploy"

  name                              = "m8t-${each.key}"
  env                               = var.env
  project_name                      = var.project_name
  namespace                         = local.k8s_namespace
  workload_identity_oidc_issuer_url = data.azurerm_kubernetes_cluster.m8t.oidc_issuer_url
  environment                       = var.env

  node_selector = var.node_selector

  resource_requests = each.value.resources.requests
  resource_limits   = each.value.resources.limits

  run_as_user  = each.value.container_user
  run_as_group = each.value.container_user

  ingress_host = (
    each.value.ingress_prefix != null && each.value.ingress_prefix != ""
    ? format("%s%s.%s", var.host_prefix, each.value.ingress_prefix, var.dns_zone_name)
    : ""
  )
}
