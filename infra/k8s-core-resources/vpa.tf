resource "kubernetes_namespace" "vpa" {
  metadata {
    name = "vpa"

    labels = {
      istio-injection = "false"
      provisioned_by  = "terraform"
    }
  }
}

resource "helm_release" "vpa" {
  depends_on = [
    kubernetes_namespace.vpa
  ]

  name       = "vpa"
  namespace  = kubernetes_namespace.vpa.metadata[0].name
  chart      = "vertical-pod-autoscaler"
  repository = "https://cowboysysop.github.io/charts/"
  version    = var.vpa_helmchart_version

  values = [
    yamlencode({
      updater = {
        nodeSelector = var.node_selector
        tolerations = var.node_selector != null ? [for k, v in var.node_selector : {
          key      = k
          operator = "Equal"
          value    = v
          effect   = "NoSchedule"
        }] : []
      }
      recommender = {
        nodeSelector = var.node_selector
        tolerations = var.node_selector != null ? [for k, v in var.node_selector : {
          key      = k
          operator = "Equal"
          value    = v
          effect   = "NoSchedule"
        }] : []
      }
      admissionController = {
        nodeSelector = var.node_selector
        tolerations = var.node_selector != null ? [for k, v in var.node_selector : {
          key      = k
          operator = "Equal"
          value    = v
          effect   = "NoSchedule"
        }] : []
      }
      crds = {
        nodeSelector = var.node_selector
        tolerations = var.node_selector != null ? [for k, v in var.node_selector : {
          key      = k
          operator = "Equal"
          value    = v
          effect   = "NoSchedule"
        }] : []
      }
    })
  ]

}
