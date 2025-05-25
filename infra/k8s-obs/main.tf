locals {
  spoke_vnet_name = "${var.project_name}-spoke-vnet"
  tolerations_from_node_selector = var.node_selector != null ? [
    for k, v in var.node_selector : {
      key      = k
      operator = "Equal"
      value    = v
      effect   = "NoSchedule"
    }
  ] : []
}

module "convention" {
  source = "../modules/az-convention"

  project     = var.project_name
  environment = var.env
  region      = var.location_short_name
}
