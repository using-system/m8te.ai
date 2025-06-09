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
  description = "The DNS zone name"
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
# Deployments Variables
#------------------------------------------------------------------------------

variable "host_prefix" {
  description = "The prefix for the hostnames"
}

variable "node_selector" {
  description = "Node selector for Kubernetes deployment"
  type        = map(string)
}

variable "components" {
  description = "Configuration for the components deployment"
  type = map(object({
    resources = object({
      requests = map(string)
      limits   = map(string)
    })
    ingress_prefix = string
    container_user = number
  }))
}

variable "otlp" {
  description = "Configuration for the otlp deployment"
  type = object({
    resources = object({
      requests = map(string)
      limits   = map(string)
    })
  })
}

#------------------------------------------------------------------------------
# Helm Chart Variables
#------------------------------------------------------------------------------

variable "keycloak_helmchart_version" {
  description = "Version of the Keycloak Helm chart to deploy"
  type        = string
  default     = "24.7.3"
}
