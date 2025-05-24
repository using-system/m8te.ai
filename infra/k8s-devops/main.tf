locals {
  spoke_vnet_name = "${var.project_name}-spoke-vnet"
}

module "convention" {
  source = "../modules/az-convention"

  project     = var.project_name
  environment = var.env
  region      = var.location_short_name
}
