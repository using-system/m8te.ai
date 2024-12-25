
resource "azurerm_private_endpoint" "pep" {
  name                = "kvpep"
  location            = var.location
  resource_group_name = data.azurerm_key_vault.hub.resource_group_name

  subnet_id = data.azurerm_subnet.resources.id

  private_dns_zone_group {
    name                 = "kvpep-dzg"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.vaultcore.id]
  }


  private_service_connection {
    name                           = "kvpep-cnx"
    private_connection_resource_id = data.azurerm_key_vault.hub.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  tags = var.tags
}
