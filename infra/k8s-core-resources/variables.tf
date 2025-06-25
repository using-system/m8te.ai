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
# Helm Chart Variables
#------------------------------------------------------------------------------

variable "node_selector" {
  description = "Node selector for Kubernetes deployment"
  type        = map(string)
}

variable "gateway_api_helmchart_version" {
  description = "Gateway API Helm Chart Version"
  default     = "2024.8.30"
}

variable "cert_manager_helmchart_version" {
  description = "Cert Manager Helm Chart Version"
  default     = "v1.17.1"
}

variable "otlp_operator_helmchart_version" {
  description = "OpenTelemetry Operator Helm Chart Version"
  default     = "0.90.4"
}

variable "vpa_helmchart_version" {
  description = "Vertical Pod Autoscaler Helm Chart Version"
  default     = "10.0.0"
}

variable "prometheus_operator_crds_helmchart_version" {
  description = "Prometheus Operator CRDs Helm Chart Version"
  default     = "19.1.0"
}
