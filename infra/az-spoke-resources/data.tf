data "azurerm_client_config" "current" {

}

data "azuread_group" "admin_group" {
  display_name     = "${upper(var.project_name)}_ADMIN"
  security_enabled = true
}

data "azurerm_subnet" "cluster" {
  name                 = "ClusterSubnet"
  virtual_network_name = local.spoke_vnet_name
  resource_group_name  = "${module.convention.resource_name}-vnet"
}

data "azurerm_subnet" "app_gtw" {
  name                 = "AppGtwSubnet"
  virtual_network_name = local.spoke_vnet_name
  resource_group_name  = "${module.convention.resource_name}-vnet"
}

data "azurerm_subnet" "resources" {
  name                 = "ResourcesSubnet"
  virtual_network_name = local.spoke_vnet_name
  resource_group_name  = "${module.convention.resource_name}-vnet"
}

data "azurerm_container_registry" "hub" {
  name                = "${var.project_name}hubinfraweacr"
  resource_group_name = "${var.project_name}-hub-infra-we-acr"
}

data "azurerm_private_dns_zone" "azmk8s" {
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = "${module.convention.resource_name}-vnet"
}

data "azurerm_private_dns_zone" "vaultcore" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = "${module.convention.resource_name}-vnet"
}

data "azurerm_key_vault" "hub" {
  name                = "${var.project_name}-hub-infra-we"
  resource_group_name = "${var.project_name}-hub-infra-we-vault"
}
