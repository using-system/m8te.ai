
locals {
  pyroscope_service_account_name = "pyroscope"
  pyroscope_container_name       = "pyroscope-data"
  pyroscope_querier_service      = "pyroscope-querier.${kubernetes_namespace.pyroscope.metadata.0.name}.svc.cluster.local"
}

resource "azurerm_resource_group" "pyroscope" {
  location = var.location
  name     = "${module.convention.resource_name}-pyroscope"

  tags = var.tags
}

resource "kubernetes_namespace" "pyroscope" {
  metadata {
    name = "pyroscope"

    labels = {
      istio-injection = "enabled"
      provisioned_by  = "terraform"
    }
  }
}

resource "kubernetes_manifest" "pyroscope_peer_authentication" {

  manifest = {
    apiVersion = "security.istio.io/v1beta1"
    kind       = "PeerAuthentication"
    metadata = {
      name      = "default"
      namespace = kubernetes_namespace.pyroscope.metadata[0].name
    }
    spec = {
      mtls = {
        mode = "PERMISSIVE"
      }
    }
  }
}

resource "azuread_application" "pyroscope" {
  #checkov:skip=CKV_AZURE_249  :  Ensure Azure GitHub Actions OIDC trust policy is configured securely
  display_name = "${var.env}-pyroscope"
}

resource "azuread_service_principal" "pyroscope" {
  client_id = azuread_application.pyroscope.client_id
}

resource "azuread_application_federated_identity_credential" "pyroscope" {
  application_id = azuread_application.pyroscope.id
  display_name   = "${var.env}-pyroscope-credential"

  audiences = ["api://AzureADTokenExchange"]
  issuer    = data.azurerm_kubernetes_cluster.m8t.oidc_issuer_url
  subject   = "system:serviceaccount:${kubernetes_namespace.pyroscope.metadata[0].name}:${local.pyroscope_service_account_name}"
}

resource "azurerm_storage_account" "pyroscope" {

  #checkov:skip=CKV_AZURE_244  : Avoid the use of local users for Azure Storage unless necessary  
  #checkov:skip=CKV_AZURE_33   : Ensure Storage logging is enabled for Queue service for read, write and delete requests
  #checkov:skip=CKV2_AZURE_33  : Ensure storage account is configured with private endpoint         
  #checkov:skip=CKV2_AZURE_41  : Ensure storage account is configured with SAS expiration policy
  #checkov:skip=CKV2_AZURE_40  : Ensure storage account is not configured with Shared Key authorization      
  #checkov:skip=CKV2_AZURE_1   : Ensure storage for critical data are encrypted with Customer Managed Key
  #checkov:skip=CKV_AZURE_206  :  Ensure that Storage Accounts use replication

  depends_on = [azurerm_resource_group.pyroscope]

  name                     = "${module.convention.resource_name_without_delimiter}pyroscope"
  resource_group_name      = azurerm_resource_group.pyroscope.name
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

resource "azurerm_role_assignment" "pyroscope_storage" {

  principal_id         = azuread_service_principal.pyroscope.object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.pyroscope.id
}

resource "azurerm_private_endpoint" "pyroscope_storage" {
  name                = "pyroscopestoragepep"
  location            = var.location
  resource_group_name = azurerm_resource_group.pyroscope.name

  subnet_id = data.azurerm_subnet.resources.id

  private_dns_zone_group {
    name                 = "pyroscopestoragepep-dzg"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.blob.id]
  }


  private_service_connection {
    name                           = "pyroscopestoragepep-cnx"
    private_connection_resource_id = azurerm_storage_account.pyroscope.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = var.tags
}

resource "time_sleep" "wait_30_seconds_after_pyroscope_storage_pep" {
  depends_on      = [azurerm_private_endpoint.pyroscope_storage]
  create_duration = "30s"
}

resource "azurerm_storage_container" "pyroscope" {

  #checkov:skip=CKV2_AZURE_21 : Ensure Storage logging is enabled for Blob service for read requests

  depends_on            = [time_sleep.wait_30_seconds_after_pyroscope_storage_pep]
  name                  = local.pyroscope_container_name
  storage_account_id    = azurerm_storage_account.pyroscope.id
  container_access_type = "private"
}

resource "helm_release" "pyroscope" {
  depends_on = [
    helm_release.prometheus,
    kubernetes_namespace.pyroscope,
    kubernetes_manifest.pyroscope_peer_authentication,
    azurerm_storage_container.pyroscope
  ]

  name       = "pyroscope"
  namespace  = kubernetes_namespace.pyroscope.metadata[0].name
  chart      = "pyroscope"
  repository = "https://grafana.github.io/helm-charts"
  version    = var.pyroscope_helmchart_version

  values = [
    yamlencode({
      pyroscope = {
        serviceAccount = {
          name = local.pyroscope_service_account_name
          annotations = {
            "azure.workload.identity/client-id" = azuread_application.pyroscope.client_id
            "azure.workload.identity/tenant-id" = data.azurerm_client_config.current.tenant_id
            "azure.workload.identity/audience"  = "api://AzureADTokenExchange"
          }
          labels = {
            "azure.workload.identity/use" = "true"
          }
        }

        structuredConfig = {
          storage = {
            backend = "azure"
            azure = {
              account_name   = azurerm_storage_account.pyroscope.name
              container_name = local.pyroscope_container_name
            }
          }
        }

        extraLabels = {
          "azure.workload.identity/use" = "true"
        }

        podAnnotations = {
          "traffic.sidecar.istio.io/excludeOutboundPorts" = "4040,7946,9095"
          "traffic.sidecar.istio.io/excludeInboundPorts"  = "4040,7946,9095"
        }

        service = {
          port_name = "grpc"
        }

        components = {
          querier = {
            kind         = "Deployment"
            replicaCount = 3
            resources = {
              limits   = { memory = "1Gi" }
              requests = { memory = "256Mi", cpu = "1" }
            }
            nodeSelector = var.node_selector
            tolerations  = local.tolerations_from_node_selector
          }

          query-frontend = {
            kind         = "Deployment"
            replicaCount = 2
            resources = {
              limits   = { memory = "1Gi" }
              requests = { memory = "256Mi", cpu = "100m" }
            }
            nodeSelector = var.node_selector
            tolerations  = local.tolerations_from_node_selector
          }

          query-scheduler = {
            kind         = "Deployment"
            replicaCount = 2
            resources = {
              limits   = { memory = "1Gi" }
              requests = { memory = "256Mi", cpu = "100m" }
            }
            nodeSelector = var.node_selector
            tolerations  = local.tolerations_from_node_selector
          }

          distributor = {
            kind         = "Deployment"
            replicaCount = 2
            labels = {
              "sidecar.istio.io/inject" = "true"
            }
            resources = {
              limits   = { memory = "1Gi" }
              requests = { memory = "256Mi", cpu = "500m" }
            }
            nodeSelector = var.node_selector
            tolerations  = local.tolerations_from_node_selector
          }

          ingester = {
            kind                          = "StatefulSet"
            replicaCount                  = 3
            terminationGracePeriodSeconds = 600
            resources = {
              limits   = { memory = "16Gi" }
              requests = { memory = "8Gi" }
            }
            nodeSelector = var.node_selector
            tolerations  = local.tolerations_from_node_selector
          }

          compactor = {
            kind                          = "StatefulSet"
            replicaCount                  = 3
            terminationGracePeriodSeconds = 1200
            persistence                   = { enabled = false }
            resources = {
              limits   = { memory = "16Gi" }
              requests = { memory = "8Gi", cpu = "1" }
            }
            nodeSelector = var.node_selector
            tolerations  = local.tolerations_from_node_selector
          }

          store-gateway = {
            kind         = "StatefulSet"
            replicaCount = 3
            persistence  = { enabled = false }
            readinessProbe = {
              initialDelaySeconds = 60
            }
            resources = {
              limits   = { memory = "16Gi" }
              requests = { memory = "8Gi", cpu = "1" }
            }
            nodeSelector = var.node_selector
            tolerations  = local.tolerations_from_node_selector
          }

          tenant-settings = {
            kind         = "Deployment"
            replicaCount = 1
            resources = {
              limits   = { memory = "4Gi" }
              requests = { memory = "16Mi", cpu = "0" }
            }
            nodeSelector = var.node_selector
            tolerations  = local.tolerations_from_node_selector
          }

          ad-hoc-profiles = {
            kind         = "Deployment"
            replicaCount = 1
            resources = {
              limits   = { memory = "4Gi" }
              requests = { memory = "16Mi", cpu = "0.1" }
            }
            nodeSelector = var.node_selector
            tolerations  = local.tolerations_from_node_selector
          }
        }
      }

      minio = {
        enabled = false
      }
    })
  ]
}
