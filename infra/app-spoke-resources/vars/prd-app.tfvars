#------------------------------------------------------------------------------
# Global Variables
#------------------------------------------------------------------------------

tags = {
  project       = "m8t"
  env           = "prd-app"
  provisionedby = "terraform"
}

#------------------------------------------------------------------------------
# Deployments Variables
#------------------------------------------------------------------------------

host_prefix = ""

node_selector = {
  "kubernetes.azure.com/scalesetpriority" = "spot"
}

resources = {
  otlp = {
    requests = { cpu = "100m", memory = "128Mi" }
    limits   = { cpu = "300m", memory = "384Mi" }
  }
  landingapp = {
    requests = { cpu = "100m", memory = "128Mi" }
    limits   = { cpu = "300m", memory = "384Mi" }
  }
  gateway = {
    requests = { cpu = "200m", memory = "256Mi" }
    limits   = { cpu = "400m", memory = "512Mi" }
  }
}
