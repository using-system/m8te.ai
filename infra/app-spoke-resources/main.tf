locals {
  k8s_namespace = "cob-${var.env}"
}

module "convention" {
  source = "../modules/az-convention"

  project     = "cob"
  environment = var.env
  region      = var.location_short_name
}

resource "azurerm_resource_group" "cob" {
  location = var.location
  name     = "${module.convention.resource_name}-app"

  tags = var.tags
}