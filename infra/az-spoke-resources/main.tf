locals {
  spoke_vnet_name  = "cob-spoke-vnet"
  hub_vnet_rg_name = "cob-hub-infra-we-vnet"
}

module "convention" {
  source = "../modules/az-convention"

  project     = "cob"
  environment = var.env
  region      = var.location_short_name
}
