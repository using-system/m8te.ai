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

variable "gha_runner_scale_set_controller_helmchart_version" {
  description = "GitHub Actions Runner Scale Set Controller Helm Chart Version"
  default     = "0.11.0"
}

variable "gha_runner_scale_set_helmchart_version" {
  description = "GitHub Actions Runner Scale Set Helm Chart Version"
  default     = "0.11.0"
}


#------------------------------------------------------------------------------
# GITHUB RUNNER Variables
#------------------------------------------------------------------------------

variable "gh_runner_app_id" {
  description = "GitHub Runner App ID"
}

variable "gh_runner_app_installation_id" {
  description = "GitHub Runner App Installation ID"
}

variable "gh_runner_app_private_key" {
  description = "GitHub Runner App Private Key"
}

variable "gh_runner_repo_url" {
  description = "GitHub Repository URL"
  default     = "https://github.com/using-system/m8te.ai"
}

variable "gh_runner_image" {
  description = "GitHub Runner Image"
  default     = "m8thubinfraweacr.azurecr.io/github-actions-runner:2025-1"
}
