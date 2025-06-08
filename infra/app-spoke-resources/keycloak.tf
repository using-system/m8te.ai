locals {
  keycloak_host = "${var.host_prefix}connect.${var.dns_zone_name}"
}

resource "kubernetes_namespace" "keycloak" {
  metadata {
    name = replace(local.k8s_namespace, "-app", "-keycloak")

    labels = {
      istio-injection = "enabled"
      provisioned_by  = "terraform"
    }
  }
}

resource "kubernetes_manifest" "keycloak_peer_authentication" {
  manifest = {
    apiVersion = "security.istio.io/v1beta1"
    kind       = "PeerAuthentication"
    metadata = {
      name      = "default"
      namespace = kubernetes_namespace.keycloak.metadata[0].name
    }
    spec = {
      mtls = {
        mode = "PERMISSIVE"
      }
    }
  }
}

resource "random_password" "keycloak_admin_user_password" {
  length  = 24
  special = true
}

resource "random_password" "keycloak_psql_admin_user_password" {
  length  = 24
  special = true
}

resource "random_password" "keycloak_psql_user_password" {
  length  = 24
  special = true
}

resource "kubernetes_secret" "keycloak_admin_user_password" {
  metadata {
    name      = "keycloak-admin-user-password"
    namespace = kubernetes_namespace.keycloak.metadata[0].name
  }
  data = {
    password = random_password.keycloak_admin_user_password.result
  }
}

resource "kubernetes_secret" "keycloak_psql_password" {
  metadata {
    name      = "keycloak-postgresql-password"
    namespace = kubernetes_namespace.keycloak.metadata[0].name
  }
  data = {
    password       = random_password.keycloak_admin_user_password.result
    admin-password = random_password.keycloak_psql_admin_user_password.result
  }
}

resource "azuread_application" "keycloak_public_login" {
  display_name     = kubernetes_namespace.keycloak.metadata[0].name
  sign_in_audience = "AzureADandPersonalMicrosoftAccount"

  api {
    requested_access_token_version = 2
  }

  web {
    redirect_uris = [
      "https://${local.keycloak_host}/realms/m8t/broker/microsoft/endpoint"
    ]
  }
}

resource "azuread_service_principal" "keycloak_public_login" {
  client_id = azuread_application.keycloak_public_login.client_id
}

resource "azuread_service_principal_password" "keycloak_public_login" {
  service_principal_id = azuread_service_principal.keycloak_public_login.id
  end_date             = "2099-01-01T00:00:00Z"
}

resource "helm_release" "keycloak" {

  depends_on = [
    kubernetes_manifest.keycloak_peer_authentication,
    kubernetes_secret.keycloak_admin_user_password,
    kubernetes_secret.keycloak_psql_password
  ]

  name       = "keycloak"
  namespace  = kubernetes_namespace.keycloak.metadata[0].name
  chart      = "keycloak"
  repository = "oci://registry-1.docker.io/bitnamicharts/"
  version    = var.keycloak_helmchart_version

  values = [
    yamlencode({
      nodeSelector = var.node_selector
      tolerations  = local.tolerations_from_node_selector

      extraEnvVars = [
        {
          name  = "KC_PROXY_HEADERS"
          value = "xforwarded"
        }
      ]

      auth = {
        adminUser         = "admin"
        existingSecret    = kubernetes_secret.keycloak_admin_user_password.metadata[0].name
        passwordSecretKey = "password"
      }

      postgresql = {
        enabled = true

        architecture = "standalone"

        auth = {
          databaseName   = "keycloak"
          userName       = "keycloak"
          existingSecret = kubernetes_secret.keycloak_psql_password.metadata[0].name
          secretKeys = {
            adminPasswordKey = "admin-password"
            userPasswordKey  = "password"
          }
        }

        primary = {
          nodeSelector = var.node_selector
          tolerations  = local.tolerations_from_node_selector
        }
      }

      keycloakConfigCli = {
        enabled = true

        nodeSelector   = var.node_selector
        podTolerations = local.tolerations_from_node_selector

        podAnnotations = {
          "sidecar.istio.io/inject" = "false"
        }

        configuration = {
          "m8t-realm.json" = {
            "realm" : "m8t",
            "displayName" : var.dns_zone_name,
            "enabled" : true,
            "registrationAllowed" : true
          }
        }
      }
    })
  ]
}

resource "kubernetes_manifest" "keycloak_http_route" {
  depends_on = [helm_release.keycloak]
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "keycloak-route"
      namespace = kubernetes_namespace.keycloak.metadata[0].name
    }
    spec = {
      parentRefs = [
        {
          name        = "gateway"
          namespace   = "istio-system"
          sectionName = "default"
        }
      ]
      hostnames = [local.keycloak_host]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]
          backendRefs = [
            {
              name = "keycloak"
              port = 80
            }
          ]
        }
      ]
    }
  }
}

resource "azurerm_dns_a_record" "keycloak" {

  name                = "${var.host_prefix}connect"
  zone_name           = var.dns_zone_name
  resource_group_name = "${var.project_name}-hub-infra-we-dns"
  ttl                 = 300
  records             = [data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].ip]
}
