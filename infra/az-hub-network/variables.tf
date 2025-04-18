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

variable "tags" {
  description = "The default tags to associate with resources."
  type        = map(string)
}

#------------------------------------------------------------------------------
# Security Variables
#------------------------------------------------------------------------------

variable "admin_group_members" {
  description = "Admin group members"
}

#------------------------------------------------------------------------------
# NETWORKING Variables
#------------------------------------------------------------------------------

variable "vnet_address_space" {
  description = "Address space for the VNET"
}

variable "vnet_subnets" {
  description = "Subnets for the VNET"
}

variable "dns_zone_name" {
  description = "DNS zone name"
  default     = "m8te.ai"

}
