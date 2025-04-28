locals {
  tempo_service_account_name = "tempo"
}

resource "azurerm_resource_group" "tempo" {
  location = var.location
  name     = "${module.convention.resource_name}-tempo"

  tags = var.tags
}

resource "kubernetes_namespace" "tempo" {
  metadata {
    name = "tempo"

    labels = {
      istio-injection = "enabled"
      provisioned_by  = "terraform"
    }
  }
}

resource "kubernetes_manifest" "tempo_peer_authentication" {

  manifest = {
    apiVersion = "security.istio.io/v1beta1"
    kind       = "PeerAuthentication"
    metadata = {
      name      = "default"
      namespace = kubernetes_namespace.tempo.metadata[0].name
    }
    spec = {
      mtls = {
        mode = "STRICT"
      }
    }
  }
}

resource "azuread_application" "tempo" {
  #checkov:skip=CKV_AZURE_249  :  Ensure Azure GitHub Actions OIDC trust policy is configured securely
  display_name = "${var.env}-tempo"
}

resource "azuread_service_principal" "tempo" {
  client_id = azuread_application.tempo.client_id
}

resource "azuread_application_federated_identity_credential" "tempo" {
  application_id = azuread_application.tempo.id
  display_name   = "${var.env}-tempo-credential"

  audiences = ["api://AzureADTokenExchange"]
  issuer    = data.azurerm_kubernetes_cluster.m8t.oidc_issuer_url
  subject   = "system:serviceaccount:${kubernetes_namespace.tempo.metadata[0].name}:${local.tempo_service_account_name}"
}

resource "azurerm_storage_account" "tempo" {

  #checkov:skip=CKV_AZURE_244  : Avoid the use of local users for Azure Storage unless necessary  
  #checkov:skip=CKV_AZURE_33   : Ensure Storage logging is enabled for Queue service for read, write and delete requests
  #checkov:skip=CKV2_AZURE_33  : Ensure storage account is configured with private endpoint         
  #checkov:skip=CKV2_AZURE_41  : Ensure storage account is configured with SAS expiration policy
  #checkov:skip=CKV2_AZURE_40  : Ensure storage account is not configured with Shared Key authorization      
  #checkov:skip=CKV2_AZURE_1   : Ensure storage for critical data are encrypted with Customer Managed Key
  #checkov:skip=CKV_AZURE_206  :  Ensure that Storage Accounts use replication

  depends_on = [azurerm_resource_group.tempo]

  name                     = "${module.convention.resource_name_without_delimiter}tempo"
  resource_group_name      = azurerm_resource_group.tempo.name
  location                 = var.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"

  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = true
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "tempo_storage" {

  principal_id         = azuread_service_principal.tempo.object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.tempo.id
}

resource "azurerm_private_endpoint" "tempo_storage" {
  name                = "tempostoragepep"
  location            = var.location
  resource_group_name = azurerm_resource_group.tempo.name

  subnet_id = data.azurerm_subnet.resources.id

  private_dns_zone_group {
    name                 = "tempostoragepep-dzg"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.blob.id]
  }


  private_service_connection {
    name                           = "tempostoragepep-cnx"
    private_connection_resource_id = azurerm_storage_account.tempo.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = var.tags
}

resource "time_sleep" "wait_30_seconds_after_tempo_storage_pep" {
  depends_on      = [azurerm_private_endpoint.tempo_storage]
  create_duration = "30s"
}
