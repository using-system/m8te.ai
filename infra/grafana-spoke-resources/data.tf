data "grafana_data_source" "prometheus" {
  name = "Prometheus"
}

data "grafana_data_source" "loki" {
  name = "Loki"
}
