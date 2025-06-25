data "azurerm_client_config" "current" {

}

data "azurerm_key_vault" "hub" {
  name                = "${var.project_name}-hub-infra-we"
  resource_group_name = "${var.project_name}-hub-infra-we-vault"
}

data "azurerm_kubernetes_cluster" "m8t" {
  name                = var.aks_cluster_name
  resource_group_name = var.aks_resource_group_name
}

data "kubernetes_service" "istio_gateway" {

  metadata {
    name      = "gateway-istio"
    namespace = "istio-system"
  }
}

data "terraform_remote_state" "k8s_obs" {
  backend = "azurerm"
  config = {
    use_oidc             = true
    resource_group_name  = "m8t-hub-we-storage"
    storage_account_name = "m8thubwetfstate"
    container_name       = "tfstates"
    key                  = "k8s-obs-${var.env-infra}.tfstate"
  }
}
