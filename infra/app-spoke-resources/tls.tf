module "cob_tls_csi" {
  source = "../modules/k8s-csi-certificate"

  k8s_namespace = kubernetes_namespace.cob.metadata[0].name

  workload_identity_oidc_issuer_url = data.azurerm_kubernetes_cluster.cob.oidc_issuer_url

  entra_tenant_id = data.azurerm_client_config.current.tenant_id
  keyvault_name   = data.azurerm_key_vault.hub.name
  keyvault_id     = data.azurerm_key_vault.hub.id

  certificate_name = "cobike"
}
