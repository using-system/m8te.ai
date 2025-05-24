data "azurerm_client_config" "current" {

}

data "azuread_group" "admin_group" {
  display_name     = "${upper(var.project_name)}_ADMIN"
  security_enabled = true
}

data "azurerm_subnet" "resources" {
  name                 = "ResourcesSubnet"
  virtual_network_name = local.spoke_vnet_name
  resource_group_name  = "${module.convention.resource_name}-vnet"
}

data "azurerm_kubernetes_cluster" "m8t" {
  name                = var.aks_cluster_name
  resource_group_name = var.aks_resource_group_name
}


data "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = "${module.convention.resource_name}-vnet"
}

data "azurerm_user_assigned_identity" "aks" {
  name                = "aks-identity"
  resource_group_name = var.aks_resource_group_name
}

data "azurerm_key_vault" "hub" {
  name                = "${var.project_name}-hub-infra-we"
  resource_group_name = "${var.project_name}-hub-infra-we-vault"
}
