#------------------------------------------------------------------------------
# Global Variables
#------------------------------------------------------------------------------

tags = {
  project       = "m8t"
  env           = "stg-infra"
  provisionedby = "terraform"
}

node_selector = {
  "kubernetes.azure.com/scalesetpriority" = "spot"
}
