
resource "azurerm_resource_group" "vnet" {
  location = var.location
  name     = "${module.convention.resource_name}-vnet"

  tags = var.tags
}

module "vnet" {
  source = "../modules/az-vnet"

  location            = var.location
  resource_group_name = azurerm_resource_group.vnet.name
  vnet_name           = "cob-hub-vnet"
  vnet_address_space  = var.vnet_address_space
  vnet_subnets        = var.vnet_subnets
  tags                = var.tags
}
