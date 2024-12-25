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

variable "tags" {
  description = "The default tags to associate with resources."
  type        = map(string)
}

#------------------------------------------------------------------------------
# NETWORKING
#------------------------------------------------------------------------------

variable "vnet_address_space" {
  description = "Address space for the VNET"
}

variable "vnet_subnets" {
  description = "Subnets for the VNET"
}

#------------------------------------------------------------------------------
# GITHUB RUNNER Variables
#------------------------------------------------------------------------------

variable "gh_runner_app_id" {
  description = "GitHub Runner App ID"
}

variable "gh_runner_app_private_key" {
  description = "GitHub Runner App Private Key"
}

variable "gh_runner_labels" {
  description = "GitHub Runner App Private Key"
}
