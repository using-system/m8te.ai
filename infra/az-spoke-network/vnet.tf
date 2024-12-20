resource "azurerm_resource_group" "vnet" {
  location = var.location
  name     = "${module.convention.resource_name}-vnet"

  tags = var.tags
}

module "vnet" {
  source = "../modules/az-vnet"

  location            = var.location
  resource_group_name = azurerm_resource_group.vnet.name
  vnet_name           = local.spoke_vnet_name
  vnet_address_space  = var.vnet_address_space
  vnet_subnets        = var.vnet_subnets
  tags                = var.tags
}

resource "azurerm_virtual_network_peering" "vnet_peering_hub_spoke" {
  name                      = "${module.convention.resource_name}-peering-hub-spoke"
  resource_group_name       = local.hub_vnet_rg_name
  virtual_network_name      = local.hub_vnet_name
  remote_virtual_network_id = module.vnet.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "vnet_peering_spoke_hub" {
  name                      = "${module.convention.resource_name}-peering-soke-hub"
  resource_group_name       = azurerm_resource_group.vnet.name
  virtual_network_name      = local.spoke_vnet_name
  remote_virtual_network_id = data.azurerm_virtual_network.hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}
