locals {
  spoke_vnet_name              = "${var.project_name}-spoke-vnet"
  formatted_github_private_key = format("-----BEGIN RSA PRIVATE KEY-----\n%s\n-----END RSA PRIVATE KEY-----", replace(var.gh_runner_app_private_key, " ", ""))
}

module "convention" {
  source = "../modules/az-convention"

  project     = var.project_name
  environment = var.env
  region      = var.location_short_name
}
