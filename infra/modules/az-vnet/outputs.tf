output "vnet_name" {
  description = "Virtual network name"
  value       = azurerm_virtual_network.vnet.name
}

output "vnet_id" {
  description = "Virtual network id"
  value       = azurerm_virtual_network.vnet.id
}

output "subnet_ids" {
  description = "Subnet ids"
  value       = { for subnet in azurerm_subnet.vnet : subnet.name => subnet.id }
}
