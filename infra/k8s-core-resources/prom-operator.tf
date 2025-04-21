resource "helm_release" "prometheus_operator_crds" {
  name             = "prometheus-operator-crds"
  namespace        = "kube-system"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus-operator-crds"
  version          = var.prometheus_operator_crds_helmchart_version
  create_namespace = false
}
