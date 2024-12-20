locals {
  hub_vnet_name    = "cob-hub-vnet"
  hub_vnet_rg_name = "cob-hub-infra-we-vnet"
  spoke_vnet_name  = "cob-spoke-vnet"
}

module "convention" {
  source = "../modules/az-convention"

  project     = "cob"
  environment = var.env
  region      = var.location_short_name
}
