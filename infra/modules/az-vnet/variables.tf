variable "location" {
  description = "Azure Location name"
}

variable "resource_group_name" {
  description = "Resource Group name"
}

variable "vnet_name" {
  description = "Subnets for the VNET"
}


variable "vnet_address_space" {
  description = "Address space for the VNET"
}

variable "vnet_subnets" {
  description = "Subnets for the VNET"
}

variable "tags" {
  description = "The default tags to associate with resources."
  type        = map(string)
}
