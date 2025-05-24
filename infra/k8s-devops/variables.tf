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
# GITHUB RUNNER Variables
#------------------------------------------------------------------------------

variable "gh_runner_image" {
  description = "GitHub Runner Image"
  default     = "myoung34/github-runner:2.324.0@sha256:59a814bb19d519f6db2f410d9955ff8eeed5cbfbaa370ef1dd5148f241dfd8fc"
}

variable "gh_runner_app_id" {
  description = "GitHub Runner App ID"
}

variable "gh_runner_app_private_key" {
  description = "GitHub Runner App Private Key"
}

variable "gh_runner_labels" {
  description = "GitHub Runner App Private Key"
}
