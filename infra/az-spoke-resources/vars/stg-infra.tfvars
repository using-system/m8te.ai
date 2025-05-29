#------------------------------------------------------------------------------
# Global Variables
#------------------------------------------------------------------------------

tags = {
  project       = "m8t"
  env           = "stg-infra"
  provisionedby = "terraform"
}

#------------------------------------------------------------------------------
# AKS Variables
#------------------------------------------------------------------------------


aks_config = {
  control_plane_version                  = "1.32.0"
  system_pool_orchestrator_version       = "1.32.0"
  os_disk_size_gb                        = 30
  system_pool_vm_size                    = "Standard_B2s"
  system_pool_size_count                 = 2
  system_pool_availability_zones         = ["2", "3"]
  user_default_pool_vm_size              = "Standard_B2s"
  user_default_pool_orchestrator_version = "1.32.0"
  user_default_pool_size_count           = 3
  user_default_pool_availability_zones   = ["2", "3"]
  user_spot_pool_vm_size                 = "Standard_D8as_v4"
  user_spot_pool_orchestrator_version    = "1.32.0"
  user_spot_pool_size_min_count          = 4
  user_spot_pool_size_max_count          = 6
  user_spot_pool_availability_zones      = ["2", "3"]
  services_cidr                          = "192.169.0.0/16"
  dns_service_ip                         = "192.169.0.10"
}
