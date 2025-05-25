#------------------------------------------------------------------------------
# Global Variables
#------------------------------------------------------------------------------

tags = {
  project       = "m8t"
  env           = "prd-infra"
  provisionedby = "terraform"
}

node_selector = {
  "kubernetes.azure.com/scalesetpriority" = "spot"
}
