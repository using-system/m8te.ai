locals {
  aks_user_node_pools = {
    for name, pool in var.aks_config.user_node_pools :
    name => merge(
      { vnet_subnet_id = data.azurerm_subnet.cluster.id },
      pool
    )
  }
}

resource "azurerm_resource_group" "aks" {
  location = var.location
  name     = "${module.convention.resource_name}-aks"

  tags = var.tags
}

resource "random_id" "aks_prefix" {
  byte_length = 8
}

resource "azurerm_user_assigned_identity" "aks" {
  location            = var.location
  name                = "aks-identity"
  resource_group_name = azurerm_resource_group.aks.name

  tags = var.tags
}

resource "azurerm_role_assignment" "aks_private_dns" {
  scope                = data.azurerm_private_dns_zone.azmk8s.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

module "aks" {

  depends_on = [azurerm_resource_group.aks, azurerm_role_assignment.aks_private_dns]

  source = "git::https://github.com/Azure/terraform-azurerm-aks.git//v4?ref=90389ee19431741fb83e4919c9cbdd4dbf0a9b46" # v 9.4.1

  cluster_name                = "${var.project_name}-aks"
  prefix                      = random_id.aks_prefix.hex
  resource_group_name         = azurerm_resource_group.aks.name
  temporary_name_for_rotation = "poolrot"

  kubernetes_version   = var.aks_config.control_plane_version
  orchestrator_version = var.aks_config.system_node_pool.orchestrator_version
  sku_tier             = "Standard"
  vnet_subnet_id       = data.azurerm_subnet.cluster.id
  private_dns_zone_id  = data.azurerm_private_dns_zone.azmk8s.id

  only_critical_addons_enabled = true
  enable_auto_scaling          = false
  agents_size                  = var.aks_config.system_node_pool.vm_size
  agents_availability_zones    = var.aks_config.system_node_pool.availability_zones
  agents_count                 = var.aks_config.system_node_pool.node_count
  agents_max_pods              = var.aks_config.system_node_pool.max_pods
  agents_pool_name             = var.aks_config.system_node_pool.name

  key_vault_secrets_provider_enabled = true
  secret_rotation_enabled            = true
  secret_rotation_interval           = "2m"

  node_pools = local.aks_user_node_pools

  azure_policy_enabled            = true
  log_analytics_workspace_enabled = false

  identity_ids                      = [azurerm_user_assigned_identity.aks.id]
  identity_type                     = "UserAssigned"
  local_account_disabled            = true
  private_cluster_enabled           = true
  rbac_aad                          = true
  rbac_aad_managed                  = true
  role_based_access_control_enabled = true
  enable_host_encryption            = true
  rbac_aad_tenant_id                = data.azurerm_client_config.current.tenant_id
  rbac_aad_admin_group_object_ids = [
    data.azuread_group.admin_group.object_id
  ]
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  network_plugin             = "azure"
  network_policy             = "azure"
  net_profile_service_cidr   = var.aks_config.services_cidr
  net_profile_dns_service_ip = var.aks_config.dns_service_ip
  node_os_channel_upgrade    = "NodeImage"
  os_disk_size_gb            = var.aks_config.system_node_pool.os_disk_size_gb

  attached_acr_id_map = {
    m8t = data.azurerm_container_registry.hub.id
  }

  maintenance_window = {
    allowed = [
      {
        day   = "Sunday",
        hours = [22, 23]
      },
    ]
  }
  maintenance_window_node_os = {
    frequency  = "Daily"
    interval   = 1
    start_time = "07:00"
    utc_offset = "+01:00"
    duration   = 16
  }

  tags = var.tags

}
