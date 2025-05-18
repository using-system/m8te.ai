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
  default     = "9.0.0"
}

variable "loki_helmchart_version" {
  description = "Loki Helm Chart Version"
  default     = "6.29.0"
}

variable "promtail_helmchart_version" {
  description = "Promtail Helm Chart Version"
  default     = "6.16.6"
}

variable "tempo_helmchart_version" {
  description = "Tempo Helm Chart Version"
  default     = "1.38.2"

}

variable "pyroscope_helmchart_version" {
  description = "Pyroscope Helm Chart Version"
  default     = "1.13.1"
}

variable "vpa_image" {
  description = "VPA Image"
  default     = "registry.k8s.io/autoscaling/vpa-recommender:1.3.0"
}
