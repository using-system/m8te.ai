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
    <<EOF
updater:
  nodeSelector:
    "kubernetes.azure.com/scalesetpriority": "spot"
  tolerations:
    - key: "kubernetes.azure.com/scalesetpriority"
      operator: "Equal"
      value: "spot"
      effect: "NoSchedule"

recommender:
  nodeSelector:
    "kubernetes.azure.com/scalesetpriority": "spot"
  tolerations:
    - key: "kubernetes.azure.com/scalesetpriority"
      operator: "Equal"
      value: "spot"
      effect: "NoSchedule"

admissionController:
  nodeSelector:
    "kubernetes.azure.com/scalesetpriority": "spot"
  tolerations:
    - key: "kubernetes.azure.com/scalesetpriority"
      operator: "Equal"
      value: "spot"
      effect: "NoSchedule"

crds:
  nodeSelector:
    "kubernetes.azure.com/scalesetpriority": "spot"
  tolerations:
    - key: "kubernetes.azure.com/scalesetpriority"
      operator: "Equal"
      value: "spot"
      effect: "NoSchedule"
EOF
  ]
}
