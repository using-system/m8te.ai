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

variable "istio_base_helmchart_version" {
  description = "Istio Base Helm Chart Version"
  default     = "1.26.1"
}

variable "istio_system_helmchart_version" {
  description = "Istio System Helm Chart Version"
  default     = "1.26.1"
}

variable "istio_gateway_helmchart_version" {
  description = "Istio Gateway Helm Chart Version"
  default     = "1.26.1"
}

#------------------------------------------------------------------------------
# Istio Variables
#------------------------------------------------------------------------------

variable "istio_system_min_replicas" {
  description = "Minimum number of replicas for Istio system components"
  type        = number
}

variable "istio_system_max_replicas" {
  description = "Maximum number of replicas for Istio system components"
  type        = number
}

variable "istio_gateway_min_replicas" {
  description = "Minimum number of replicas for Istio gateway"
  type        = number
}

variable "istio_gateway_max_replicas" {
  description = "Maximum number of replicas for Istio gateway"
  type        = number
}
