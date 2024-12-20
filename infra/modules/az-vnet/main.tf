
resource "azurerm_network_security_group" "vnet" {

  for_each = {
    for subnet in var.vnet_subnets : subnet.name => subnet
    if subnet.name != "GatewaySubnet"
  }

  name                = "${each.key}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name


  dynamic "security_rule" {
    for_each = each.value.network_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_address_prefix      = security_rule.value.source_address_prefix
      source_port_range          = security_rule.value.source_port_range
      destination_address_prefix = security_rule.value.destination_address_prefix
      destination_port_range     = security_rule.value.destination_port_range
    }
  }

  tags = var.tags
}

resource "azurerm_route_table" "vnet" {

  for_each = {
    for subnet in var.vnet_subnets : subnet.name => subnet
    if subnet.name != "AzureBastionSubnet"
  }

  name                          = "${each.key}-rt"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  bgp_route_propagation_enabled = true

  dynamic "route" {
    for_each = each.value.routes
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = route.value.next_hop_in_ip_address
    }
  }

  tags = var.tags

}

resource "azurerm_virtual_network" "vnet" {

  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name

  address_space = [var.vnet_address_space]

  tags = var.tags
}

resource "azurerm_subnet" "vnet" {


  for_each = { for subnet in var.vnet_subnets : subnet.name => subnet }

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints
}

resource "azurerm_subnet_network_security_group_association" "vnet" {

  for_each = azurerm_network_security_group.vnet

  subnet_id                 = azurerm_subnet.vnet[each.key].id
  network_security_group_id = azurerm_network_security_group.vnet[each.key].id
}


resource "azurerm_subnet_route_table_association" "vnet" {

  for_each = azurerm_route_table.vnet

  subnet_id      = azurerm_subnet.vnet[each.key].id
  route_table_id = azurerm_route_table.vnet[each.key].id
}
