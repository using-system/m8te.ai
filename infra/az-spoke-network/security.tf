resource "azuread_group" "admin" {
  display_name     = "COB_ADMIN"
  owners           = [data.azurerm_client_config.current.object_id]
  security_enabled = true

  lifecycle {
    ignore_changes = [owners]
  }
}

resource "azuread_group_member" "admin" {
  for_each         = toset(var.admin_group_members)
  group_object_id  = azuread_group.admin.object_id
  member_object_id = each.key
}
