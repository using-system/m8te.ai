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

variable "ingress_prefix" {
  description = "Ingress prefix"
}


#------------------------------------------------------------------------------
# Helm Chart Variables
#------------------------------------------------------------------------------

variable "prometheus_helmchart_version" {
  description = "Prometheus Helm Chart Version"
  default     = "26.0.1"
}

variable "thanos_helmchart_version" {
  description = "TJ Helm Chart Version"
  default     = "15.9.2"
}

variable "thanos_sidecar_image" {
  description = "Thanos Sidecar Image"
  default     = "quay.io/thanos/thanos:v0.37.2"
}

variable "grafana_helmchart_version" {
  description = "Grafana Helm Chart Version"
  default     = "8.8.2"
}

variable "otel_collector_helmchart_version" {
  description = "OpenTelemetry Collector Helm Chart Version"
  default     = "0.116.0"
}

variable "kubecost_helmchart_version" {
  description = "Kubecost Helm Chart Version"
  default     = "2.7.1"
}
