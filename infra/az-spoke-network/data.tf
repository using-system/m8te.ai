data "azurerm_client_config" "current" {

}

data "azurerm_virtual_network" "hub" {
  name                = local.hub_vnet_name
  resource_group_name = local.hub_vnet_rg_name
}

data "azurerm_container_registry" "hub" {
  name                = "${var.project_name}hubinfraweacr"
  resource_group_name = "${var.project_name}-hub-infra-we-acr"
}
