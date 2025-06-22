#------------------------------------------------------------------------------
# Global Variables
#------------------------------------------------------------------------------

tags = {
  project       = "m8t"
  env           = "dev-app"
  provisionedby = "terraform"
}

#------------------------------------------------------------------------------
# Deployments Variables
#------------------------------------------------------------------------------

host_prefix = "dev-"

node_selector = {
  "kubernetes.azure.com/scalesetpriority" = "spot"
}

components = {
  landing-app = {
    resources = {
      requests = { cpu = "50m", memory = "128Mi" }
      limits   = { cpu = "300m", memory = "384Mi" }
    }
    ingress_prefix = "www"
    container_user = 1001
  }
  gateway = {
    resources = {
      requests = { cpu = "100m", memory = "256Mi" }
      limits   = { cpu = "400m", memory = "512Mi" }
    }
    ingress_prefix = "api"
    container_user = 1654
  }
  accountms = {
    resources = {
      requests = { cpu = "50m", memory = "128Mi" }
      limits   = { cpu = "300m", memory = "384Mi" }
    }
    ingress_prefix = ""
    container_user = 1001
  }
}

otlp = {
  resources = {
    requests = { cpu = "25m", memory = "100Mi" }
    limits   = { cpu = "150m", memory = "384Mi" }
  }
}
