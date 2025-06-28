resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "prometheus"

    labels = {
      provisioned_by = "terraform"
    }
  }

}

resource "helm_release" "kube_state_metrics" {


  name       = "kube-state-metrics"
  namespace  = kubernetes_namespace.prometheus.metadata[0].name
  chart      = "kube-state-metrics"
  repository = "https://prometheus-community.github.io/helm-charts"
  version    = var.kube_state_metrics_helmchart_version

  values = [
    yamlencode({
      nodeSelector = var.node_selector
      tolerations  = local.tolerations_from_node_selector
    })
  ]
}

resource "helm_release" "prometheus_node_exporter" {

  name       = "prometheus-node-exporter"
  namespace  = kubernetes_namespace.prometheus.metadata[0].name
  chart      = "prometheus-node-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  version    = var.prometheus_node_exporter_helmchart_version

  values = [
    yamlencode({
    })
  ]
}
