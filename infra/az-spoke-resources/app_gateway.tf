resource "azurerm_resource_group" "app_gtw" {
  location = var.location
  name     = "${module.convention.resource_name}-gtw"

  tags = var.tags
}

locals {
  vnet_name                          = "cob-vnet"
  gtw_backend_address_pool_name      = "${local.vnet_name}-beap"
  gtw_frontend_port_name             = "${local.vnet_name}-feport"
  gtw_frontend_ip_configuration_name = "${local.vnet_name}-feip"
  gtw_http_setting_name              = "${local.vnet_name}-be-htst"
  gtw_listener_name                  = "${local.vnet_name}-httplstn"
  gtw_request_routing_rule_name      = "${local.vnet_name}-rqrt"
  gtw_redirect_configuration_name    = "${local.vnet_name}-rdrcfg"
}

resource "azurerm_public_ip" "app_gtw" {
  allocation_method   = "Static"
  location            = var.location
  name                = "cob-gtw-pip"
  resource_group_name = azurerm_resource_group.app_gtw.name
  sku                 = "Standard"
}

resource "azurerm_user_assigned_identity" "app_gtw" {
  location            = var.location
  name                = "app_gtw-identity"
  resource_group_name = azurerm_resource_group.app_gtw.name

  tags = var.tags
}

resource "azurerm_role_assignment" "app_gtw_vault" {
  scope                = data.azurerm_key_vault.hub.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = azurerm_user_assigned_identity.app_gtw.principal_id
}

resource "azurerm_application_gateway" "app_gtw" {
  #checkov:skip=CKV_AZURE_120   :   Ensure that Application Gateway enables WAF 
  #checkov:skip=CKV_AZURE_218   :   Ensure Application Gateway defines secure protocols for in transit communication
  #checkov:skip=CKV_AZURE_217    :  Ensure Azure Application gateways listener that allow connection requests over HTTP

  depends_on = [azurerm_private_endpoint.pep, azurerm_role_assignment.app_gtw_vault]

  name                = "cob-gtw"
  resource_group_name = azurerm_resource_group.app_gtw.name
  location            = var.location

  sku {
    name     = var.app_gtw_config.sku_name
    tier     = var.app_gtw_config.sku_tier
    capacity = var.app_gtw_config.sku_capacity
  }

  enable_http2 = true

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.app_gtw.id
    ]
  }

  gateway_ip_configuration {
    name      = "cob-gtw-ip-config"
    subnet_id = data.azurerm_subnet.app_gtw.id
  }

  frontend_port {
    name = local.gtw_frontend_port_name
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.gtw_frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.app_gtw.id
  }

  backend_address_pool {
    name = local.gtw_backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.gtw_http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  ssl_certificate {
    name                = "cobike-cert"
    key_vault_secret_id = data.azurerm_key_vault_certificate.cobike.secret_id
  }

  http_listener {
    name                           = local.gtw_listener_name
    frontend_ip_configuration_name = local.gtw_frontend_ip_configuration_name
    frontend_port_name             = local.gtw_frontend_port_name
    protocol                       = "Https"
    ssl_certificate_name           = "cobike-cert"
  }

  request_routing_rule {
    name                       = local.gtw_request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.gtw_listener_name
    backend_address_pool_name  = local.gtw_backend_address_pool_name
    backend_http_settings_name = local.gtw_http_setting_name
  }

  lifecycle {
    ignore_changes = [
      tags,
      backend_address_pool,
      backend_http_settings,
      http_listener,
      probe,
      request_routing_rule,
      url_path_map,
      frontend_port,
      redirect_configuration
    ]
  }

  tags = var.tags
}
