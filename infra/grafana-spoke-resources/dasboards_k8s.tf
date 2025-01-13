locals {
  k8s_dashboards = ["kube-state-metrics-v2"]
}

resource "grafana_folder" "k8s" {
  title = "K8S"
}

resource "grafana_dashboard" "k8s" {
  for_each = toset(local.k8s_dashboards)

  folder      = grafana_folder.k8s.id
  config_json = file("${path.module}/dashboards/k8s/${each.value}.json")
}
