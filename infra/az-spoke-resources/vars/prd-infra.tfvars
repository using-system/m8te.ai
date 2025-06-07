#------------------------------------------------------------------------------
# Global Variables
#------------------------------------------------------------------------------

tags = {
  project       = "m8t"
  env           = "prd-infra"
  provisionedby = "terraform"
}

#------------------------------------------------------------------------------
# AKS Variables
#------------------------------------------------------------------------------

aks_config = {
  control_plane_version = "1.33.0"
  services_cidr         = "192.169.0.0/16"
  dns_service_ip        = "192.169.0.10"
  system_node_pool = {
    name                 = "systempool"
    orchestrator_version = "1.33.0"
    vm_size              = "Standard_B2s"
    availability_zones   = ["2", "3"]
    os_disk_size_gb      = 30
    node_count           = 2
    max_pods             = 100
  }
  user_node_pools = {
    UserDefaultPool = {
      name                 = "default"
      orchestrator_version = "1.33.0"
      zones                = ["2", "3"]
      vm_size              = "Standard_B2s"
      os_disk_size_gb      = 30
      priority             = "Regular"
      node_count           = 3
      max_pods             = 100
      enable_auto_scaling  = false
      upgrade_settings = {
        max_surge                     = "10%"
        drain_timeout_in_minutes      = 0
        node_soak_duration_in_minutes = 0
      }
      create_before_destroy = true
    }
    UserSpotPool = {
      name                  = "spot"
      orchestrator_version  = "1.33.0"
      zones                 = ["2", "3"]
      vm_size               = "Standard_D8as_v4"
      os_disk_size_gb       = 30
      os_disk_type          = "Ephemeral"
      priority              = "Spot"
      eviction_policy       = "Delete"
      min_count             = 4
      max_count             = 6
      max_pods              = 100
      enable_auto_scaling   = true
      node_taints           = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]
      create_before_destroy = true
    }
  }
}

