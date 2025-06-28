output "grafana_config" {
  description = "Configuration for Grafana cloud satck"
  value = {
    global = {
      auth         = var.grafana_auth
      cluster_name = var.grafana_cluster_name
    }
    otlp = {
      endpoint = var.grafana_otlp_url
      username = var.grafana_otlp_username
    }
    loki = {
      endpoint = var.grafana_loki_push_url
      username = var.grafana_loki_username
    }
    prometheus = {
      endpoint = var.grafana_prometheus_push_url
      username = var.grafana_prometheus_username
    }
  }
}
