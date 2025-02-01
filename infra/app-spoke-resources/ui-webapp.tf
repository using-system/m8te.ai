module "ui_webapp" {

  depends_on = [kubernetes_namespace.cob]

  source = "../modules/k8s-deploy"

  name                              = "webapp"
  namespace                         = local.k8s_namespace
  workload_identity_oidc_issuer_url = data.azurerm_kubernetes_cluster.cob.oidc_issuer_url
  environment                       = var.env
  replicas                          = 5

  resource_requests = {
    cpu    = var.ui_webapp_cpu_request
    memory = var.ui_webapp_memory_request
  }

  ingress_host = "${var.host_prefix}app.co.bike"
}
