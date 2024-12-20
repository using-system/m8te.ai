module "convention" {
  source = "../modules/az-convention"

  project     = "cob"
  environment = var.env
  region      = var.location_short_name
}
