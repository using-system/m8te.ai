#------------------------------------------------------------------------------
# Global Variables
#------------------------------------------------------------------------------

tags = {
  project       = "m8t"
  env           = "stg-infra"
  provisionedby = "terraform"
}

#------------------------------------------------------------------------------
# Kubernetes Variables
#------------------------------------------------------------------------------

node_selector = {
  "kubernetes.azure.com/scalesetpriority" = "spot"
}

ingress_prefix = "stg-"

#------------------------------------------------------------------------------
# Grafana Variables
#------------------------------------------------------------------------------

grafana_cluster_name        = "stg-m8t-aks"
grafana_otlp_url            = "https://otlp-gateway-prod-eu-west-2.grafana.net/otlp"
grafana_otlp_username       = "1298944"
grafana_prometheus_push_url = "https://prometheus-prod-24-prod-eu-west-2.grafana.net./api/prom/push"
grafana_prometheus_username = "2522123"
grafana_loki_push_url       = "https://logs-prod-012.grafana.net./loki/api/v1/push"
grafana_loki_username       = "1256738"
