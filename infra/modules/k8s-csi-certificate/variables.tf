variable "k8s_namespace" {
  description = "The namespace of the deployment"
  type        = string
}

variable "workload_identity_oidc_issuer_url" {
  description = "The OIDC issuer URL of the workload identity"
  type        = string
}

variable "entra_tenant_id" {
  description = "The tenant id of the keyvault where the certificate is stored"
  type        = string
}

variable "keyvault_name" {
  description = "The name of the keyvault where the certificate is stored"
  type        = string
}

variable "keyvault_id" {
  description = "The id of the keyvault where the certificate is stored"
  type        = string
}

variable "certificate_name" {
  description = "The name of the certificate to mount as k8s secret"
  type        = string
}

variable "certificate_content_type" {
  description = "The content type of the certificate"
  type        = string
  default     = "application/x-pkcs12"
}
