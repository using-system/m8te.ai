resource "azuread_group" "admin" {
  display_name     = "${upper(module.convention.project)}_ADMIN"
  owners           = [data.azurerm_client_config.current.object_id]
  security_enabled = true

  lifecycle {
    ignore_changes = [owners]
  }
}

resource "azuread_group_member" "admin_users" {
  for_each         = toset(var.admin_group_members)
  group_object_id  = azuread_group.admin.object_id
  member_object_id = each.key
}

resource "azuread_group_member" "admin_devops_principal" {
  group_object_id  = azuread_group.admin.object_id
  member_object_id = data.azurerm_client_config.current.object_id
}
