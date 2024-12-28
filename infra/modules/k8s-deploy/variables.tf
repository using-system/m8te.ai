variable "name" {
  description = "The name of the deployment"
  type        = string
}

variable "namespace" {
  description = "The namespace of the deployment"
  type        = string
}

variable "aks_cluster_name" {
  description = "The name of the AKS cluster"
  type        = string
}

variable "aks_resource_group_name" {
  description = "The name of the resource group containing the AKS cluster"
  type        = string
}

variable "replicas" {
  description = "The number of replicas"
  type        = number
  default     = 2
}

variable "strategy" {
  description = "The deployment strategy"
  type        = string
  default     = "RollingUpdate"
}

variable "env_vars" {
  description = "Map of environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "default_image" {
  description = "The default image to use if not specified in the container definition"
  type        = string
  default     = "cobhubinfraweacr.azurecr.io/blankapp:0.1.0@sha256:979bd00d89e8ac42c9b949688e8fcba7d82e3f8710468bfc5053728c43d15bb3"
}

variable "volume_claims" {
  description = "List of volume claims and mount paths."
  type = list(object({
    claim_name = string
    mount_path = string
    read_only  = bool
  }))
  default = []
}

variable "port" {
  description = "The port the container listens on"
  type        = number
  default     = 3000
}

variable "read_only_root_filesystem" {
  description = "Mount the root filesystem as read-only"
  type        = bool
  default     = true
}

variable "run_as_user" {
  description = "The user ID that runs the container"
  type        = number
  default     = 1001
}

variable "run_as_group" {
  description = "The group ID that runs the container"
  type        = number
  default     = 1001
}

variable "environment" {
  description = "The environment to deploy to"
  type        = string
}

variable "resource_limits" {
  description = "Resource limits for the container"
  type        = map(string)
  default = {
    cpu    = "500m"
    memory = "2048Mi"
  }
}

variable "resource_requests" {
  description = "Resource requests for the container"
  type        = map(string)
}

variable "role_assignments" {
  description = "HashSet of scopeId and roleName for IAM role assignments"
  type = list(object({
    scope_id  = string
    role_name = string
  }))
  default = []
}

variable "health_probe_transport_mode" {
  description = "The transport mode for the health probe of the container. http or grpc"
  type        = string
  default     = "http"
}

variable "health_probe_path" {
  description = "The path for the health probe of the container"
  type        = string
  default     = "/health"
}

variable "ingress_host" {
  description = "The host for the ingress"
  type        = string
}
