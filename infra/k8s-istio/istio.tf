resource "kubernetes_namespace" "istio" {
  metadata {
    name = "istio-system"
  }
}

module "istio_tls_csi" {

  depends_on = [kubernetes_namespace.istio]

  source = "../modules/k8s-csi-certificate"

  env           = var.env
  project_name  = var.project_name
  k8s_namespace = kubernetes_namespace.istio.metadata[0].name

  node_selector = var.node_selector

  workload_identity_oidc_issuer_url = data.azurerm_kubernetes_cluster.m8t.oidc_issuer_url

  entra_tenant_id = data.azurerm_client_config.current.tenant_id
  keyvault_name   = data.azurerm_key_vault.hub.name
  keyvault_id     = data.azurerm_key_vault.hub.id

  certificate_name = var.project_name
}

resource "helm_release" "istio_base" {

  depends_on = [kubernetes_namespace.istio]

  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  version          = var.istio_base_helmchart_version
  create_namespace = false
  namespace        = kubernetes_namespace.istio.metadata[0].name
  values = [
    <<EOF
EOF
  ]
}

resource "helm_release" "istio_system" {

  depends_on = [helm_release.istio_base]

  name             = "istiod"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "istiod"
  version          = var.istio_system_helmchart_version
  create_namespace = false
  namespace        = kubernetes_namespace.istio.metadata[0].name
  values = [
    yamlencode({
      nodeSelector = var.node_selector
      tolerations = var.node_selector != null ? [for k, v in var.node_selector : {
        key      = k
        operator = "Equal"
        value    = v
        effect   = "NoSchedule"
      }] : []
      autoscaleEnabled = true
      autoscaleMin     = var.istio_system_min_replicas
      autoscaleMax     = var.istio_system_max_replicas
      resources = {
        requests = {
          memory = "128Mi"
        }
      }
    })
  ]
}

resource "kubernetes_manifest" "istio_api_gateway" {
  depends_on = [module.istio_tls_csi, helm_release.istio_system]
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "gateway"
      namespace = kubernetes_namespace.istio.metadata[0].name
      annotations = {
        "service.beta.kubernetes.io/port_443_health-probe_protocol" = "tcp"
      }
    }
    spec = {
      gatewayClassName = "istio"
      listeners = [
        {
          name     = "default"
          protocol = "HTTPS"
          port     = 443
          tls = {
            mode = "Terminate"
            certificateRefs = [
              {
                namespace = kubernetes_namespace.istio.metadata[0].name
                name      = module.istio_tls_csi.k8s_secret_name
              }
            ]
          }
          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }
        }
      ]
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "istio_api_gateway" {

  depends_on = [kubernetes_manifest.istio_api_gateway]

  metadata {
    name      = "gateway"
    namespace = kubernetes_namespace.istio.metadata[0].name
  }
  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "gateway-istio"
    }
    min_replicas = var.istio_gateway_min_replicas
    max_replicas = var.istio_gateway_max_replicas
    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
  }
}

resource "kubernetes_pod_disruption_budget_v1" "istio_api_gateway" {

  depends_on = [kubernetes_manifest.istio_api_gateway]


  metadata {
    name      = "gateway"
    namespace = kubernetes_namespace.istio.metadata[0].name
  }
  spec {
    min_available = 1
    selector {
      match_labels = {
        "gateway.networking.k8s.io/gateway-name" = "gateway"
      }
    }
  }
}
