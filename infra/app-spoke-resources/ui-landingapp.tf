module "ui_landingapp" {

  depends_on = [kubernetes_namespace.cob]

  source = "../modules/k8s-deploy"

  name                    = "landingapp"
  namespace               = local.k8s_namespace
  aks_cluster_name        = var.aks_cluster_name
  aks_resource_group_name = var.aks_resource_group_name
  environment             = var.env
  replicas                = 5

  resource_requests = {
    cpu    = var.ui_landingapp_cpu_request
    memory = var.ui_landingapp_memory_request
  }

  ingress_host = "${var.host_prefix}www.co.bike"
}
