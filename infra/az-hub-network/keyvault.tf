resource "azurerm_resource_group" "vault" {
  location = var.location
  name     = "${module.convention.resource_name}-vault"

  tags = var.tags
}

resource "azurerm_key_vault" "vault" {
  #checkov:skip=CKV2_AZURE_32 :  Ensure private endpoint is configured to key vault
  name                = module.convention.resource_name
  location            = var.location
  resource_group_name = azurerm_resource_group.vault.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  enable_rbac_authorization       = true
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  purge_protection_enabled        = true

  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    virtual_network_subnet_ids = [module.vnet.subnet_ids["ResourcesSubnet"]]
  }
  public_network_access_enabled = false


  tags = var.tags

}

resource "azurerm_role_assignment" "key_vault_admin" {
  scope                = azurerm_key_vault.vault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = azuread_group.admin.object_id
}

