#------------------------------------------------------------------------------
# Global Variables
#------------------------------------------------------------------------------

variable "azure_subscription_id" {
  description = "Azure Subscription ID"
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID"
}

variable "location" {
  description = "Azure Location name"
  default     = "westeurope"
}

variable "location_short_name" {
  description = "Azure Location short name"
  default     = "we"
}

variable "env" {
  description = "Environment name"
}

variable "project_name" {
  description = "Project name"
  default     = "m8t"
}

variable "dns_zone_name" {
  description = "DNS Zone Name"
  default     = "m8te.ai"
}

variable "tags" {
  description = "The default tags to associate with resources."
  type        = map(string)
}

#------------------------------------------------------------------------------
# AKS Variables
#------------------------------------------------------------------------------

variable "aks_cluster_name" {
  description = "The name of the AKS cluster"
}

variable "aks_resource_group_name" {
  description = "The name of the resource group containing the AKS cluster"
}

#------------------------------------------------------------------------------
# Kubernetes Variables
#------------------------------------------------------------------------------

variable "node_selector" {
  description = "Node selector for Kubernetes deployment"
  type        = map(string)
}

variable "ingress_prefix" {
  description = "Ingress prefix"
}


#------------------------------------------------------------------------------
# Grafana Variables
#------------------------------------------------------------------------------

variable "grafana_auth" {
  type = string
}

variable "grafana_cluster_name" {
  type = string
}

variable "grafana_otlp_url" {
  type = string
}

variable "grafana_otlp_username" {
  type = string
}

variable "grafana_prometheus_push_url" {
  type = string
}

variable "grafana_prometheus_username" {
  type = string
}

variable "grafana_loki_push_url" {
  type = string
}

variable "grafana_loki_username" {
  type = string
}

#------------------------------------------------------------------------------
# Helm Chart Variables
#------------------------------------------------------------------------------

variable "kube_state_metrics_helmchart_version" {
  description = "Version of the kube-state-metrics Helm chart to deploy"
  type        = string
  default     = "6.0.0"
}

variable "prometheus_node_exporter_helmchart_version" {
  description = "Version of the prometheus-node-exporter Helm chart to deploy"
  type        = string
  default     = "4.47.0"
}
