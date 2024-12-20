data "azurerm_client_config" "current" {

}

data "azuread_group" "admin_group" {
  display_name     = "COB_ADMIN"
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

data "azurerm_container_registry" "hub" {
  name                = "cobhubinfraweacr"
  resource_group_name = "cob-hub-infra-we-acr"
}
