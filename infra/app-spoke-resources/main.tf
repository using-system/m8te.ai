locals {
  prometheus_server_service     = "prometheus-server.prometheus.svc.cluster.local"
  loki_gateway_service          = "loki-gateway.loki.svc.cluster.local"
  tempo_gateway_service         = "tempo-gateway.tempo.svc.cluster.local"
  pyroscope_distributor_service = "pyroscope-distributor.pyroscope.svc.cluster.local"
  k8s_namespace                 = "${var.project_name}-${var.env}"
}

module "convention" {
  source = "../modules/az-convention"

  project     = var.project_name
  environment = var.env
  region      = var.location_short_name
}

resource "azurerm_resource_group" "app" {
  location = var.location
  name     = "${module.convention.resource_name}-app"

  tags = var.tags
}
