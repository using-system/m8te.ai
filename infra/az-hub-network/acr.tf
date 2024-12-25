resource "azurerm_resource_group" "acr" {
  location = var.location
  name     = "${module.convention.resource_name}-acr"

  tags = var.tags
}

resource "azurerm_user_assigned_identity" "acr" {
  location            = var.location
  name                = "acr-identity"
  resource_group_name = azurerm_resource_group.acr.name

  tags = var.tags
}

resource "azurerm_container_registry" "acr" {
  # Disable checkov for the following rules because to do not have budget for a premium SKU
  #checkov:skip=CKV_AZURE_139  :  Ensure ACR set to disable public networking 
  #checkov:skip=CKV_AZURE_166  : Ensure container image quarantine, scan, and mark images verified  
  #checkov:skip=CKV_AZURE_165  : Ensure geo-replicated container registries to match multi-region container deployments 
  #checkov:skip=CKV_AZURE_167  : Ensure a retention policy is set to cleanup untagged manifests. 
  #checkov:skip=CKV_AZURE_233  : Ensure Azure Container Registry (ACR) is zone redundant        
  #checkov:skip=CKV_AZURE_237  : Ensure dedicated data endpoints are enabled. 
  #checkov:skip=CKV_AZURE_164  : Ensures that ACR uses signed/trusted images         
  location            = var.location
  resource_group_name = azurerm_resource_group.acr.name
  name                = "${module.convention.resource_name_without_delimiter}acr"
  sku                 = "Standard"
  admin_enabled       = false

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.acr.id]
  }

  tags = var.tags
}
