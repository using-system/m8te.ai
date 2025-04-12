resource "azurerm_resource_group" "aca" {
  location = var.location
  name     = "${module.convention.resource_name}-aca"

  tags = var.tags
}

resource "azurerm_container_app_environment" "aca" {
  location                 = var.location
  name                     = "${var.project_name}-aca-env"
  resource_group_name      = azurerm_resource_group.aca.name
  infrastructure_subnet_id = module.vnet.subnet_ids["AcaSubnet"]
}

