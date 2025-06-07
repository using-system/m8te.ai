locals {
  keycloak_host = "${var.host_prefix}connect.${var.dns_zone_name}"
}

resource "helm_release" "keycloak" {
  depends_on = [
    kubernetes_manifest.peer_authentication
  ]

  name       = "keycloak"
  namespace  = kubernetes_namespace.app.metadata[0].name
  chart      = "keycloak"
  repository = "oci://registry-1.docker.io/bitnamicharts/"
  version    = var.keycloak_helmchart_version

  values = [
    yamlencode({
      nodeSelector = var.node_selector
      tolerations  = local.tolerations_from_node_selector

      extraEnvVars = [
        {
          name  = "KC_PROXY"
          value = "edge"
        },
        {
          name  = "KC_HOSTNAME"
          value = "${local.keycloak_host}"
        },
        {
          name  = "KC_FRONTEND_URL"
          value = "https://${local.keycloak_host}"
        },
        {
          name  = "KC_HOSTNAME_STRICT"
          value = "false"
        }
      ]
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
      namespace = kubernetes_namespace.app.metadata[0].name
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
