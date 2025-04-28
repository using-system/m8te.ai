locals {
  csi_name                 = "${var.certificate_name}-csi"
  k8s_service_account_name = "${var.certificate_name}-csi-sa"
  k8s_secret_name          = "${var.certificate_name}-tls"
}

resource "azuread_application" "this" {
  #checkov:skip=CKV_AZURE_249  :  Ensure Azure GitHub Actions OIDC trust policy is configured securely
  display_name = "${var.project_name}-${var.env}-${var.k8s_namespace}-${local.csi_name}"
}

resource "azuread_service_principal" "this" {
  client_id = azuread_application.this.client_id
}


resource "kubernetes_service_account" "this" {
  metadata {
    name      = local.k8s_service_account_name
    namespace = var.k8s_namespace
    annotations = {
      "azure.workload.identity/client-id" = azuread_application.this.client_id
      "azure.workload.identity/tenant-id" = var.entra_tenant_id
    }
    labels = {
      "azure.workload.identity/use" : "true"
    }
  }
}

resource "azuread_application_federated_identity_credential" "this" {
  application_id = azuread_application.this.id
  display_name   = "${var.k8s_namespace}-${var.certificate_name}-credential"

  audiences = ["api://AzureADTokenExchange"]
  issuer    = var.workload_identity_oidc_issuer_url
  subject   = "system:serviceaccount:${var.k8s_namespace}:${local.k8s_service_account_name}"
}

resource "azurerm_role_assignment" "this" {

  principal_id         = azuread_service_principal.this.object_id
  role_definition_name = "Key Vault Secrets User"
  scope                = var.keyvault_id
}

resource "kubernetes_manifest" "grafana_tls_secret" {
  manifest = {
    "apiVersion" = "secrets-store.csi.x-k8s.io/v1"
    "kind"       = "SecretProviderClass"
    "metadata" = {
      "name"      = local.csi_name
      "namespace" = var.k8s_namespace
    }
    "spec" = {
      "provider" = "azure"
      "secretObjects" = [
        {
          "secretName" = local.k8s_secret_name
          "type"       = "kubernetes.io/tls"
          "data" = [
            {
              "objectName" = var.certificate_name
              "key"        = "tls.crt"
            },
            {
              "objectName" = var.certificate_name
              "key"        = "tls.key"
            }
          ]
        }
      ]
      "parameters" = {
        "useWorkloadIdentity"  = "true"
        "usePodIdentity"       = "false"
        "useVMManagedIdentity" = "false"
        "clientID"             = azuread_application.this.client_id
        "keyvaultName"         = var.keyvault_name
        "objects"              = <<-EOF
          array:
            - |
              objectName: "${var.certificate_name}"
              objectType: "secret"
              contentType: "application/x-pkcs12"
        EOF
        "tenantId"             = var.entra_tenant_id
        "cloudName"            = "AzurePublicCloud"
      }
    }
  }
}

resource "kubernetes_deployment" "this" {
  depends_on = [kubernetes_manifest.grafana_tls_secret, azurerm_role_assignment.this]
  metadata {
    name      = local.csi_name
    namespace = var.k8s_namespace
    labels = {
      provisioned_by = "terraform"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = local.csi_name
      }
    }

    template {
      metadata {
        labels = {
          app                           = local.csi_name
          "azure.workload.identity/use" = "true"
          provisioned_by                = "terraform"
        }
      }

      spec {

        node_selector = {
          "kubernetes.azure.com/scalesetpriority" = "spot"
        }

        toleration {
          key      = "kubernetes.azure.com/scalesetpriority"
          operator = "Equal"
          value    = "spot"
          effect   = "NoSchedule"
        }

        security_context {
          run_as_user  = 1000
          run_as_group = 1000
          fs_group     = 1000
        }


        service_account_name = local.k8s_service_account_name

        container {
          name    = "alpine"
          image   = "alpine:3.21.2@sha256:56fa17d2a7e7f168a043a2712e63aed1f8543aeafdcee47c58dcffe38ed51099"
          command = ["/bin/sh", "-c"]
          args    = ["echo 'Triggering secrets-store creation...' && sleep 999999"]

          resources {
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
          }

          readiness_probe {
            exec {
              command = ["/bin/sh", "-c", "echo 'readiness check'"]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 2
          }

          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
            read_only_root_filesystem = true
            run_as_non_root           = true
          }

          liveness_probe {
            exec {
              command = ["/bin/sh", "-c", "echo 'liveness check'"]
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 2
          }

          volume_mount {
            name       = local.csi_name
            mount_path = "/mnt/csi"
            read_only  = true
          }
        }

        volume {
          name = local.csi_name

          csi {
            driver    = "secrets-store.csi.k8s.io"
            read_only = true
            volume_attributes = {
              "secretProviderClass" = local.csi_name
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      spec[0].template[0].metadata[0].annotations["kubectl.kubernetes.io/restartedAt"]
    ]
  }
}
