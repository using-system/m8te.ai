variable "name" {
  description = "The name of the deployment"
  type        = string
}

variable "namespace" {
  description = "The namespace of the deployment"
  type        = string
}

variable "env" {
  description = "The environment of the deployment"
  type        = string
}

variable "project_name" {
  description = "The project name of the deployment"
  type        = string
}

variable "workload_identity_oidc_issuer_url" {
  description = "The OIDC issuer URL of the workload identity"
  type        = string
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
  default     = "m8thubinfraweacr.azurecr.io/blankapp:0.1.0@sha256:319589057dfd597a11344d4649342b275fbc2935b1dc75a1d6be90f9b377ea15"
}

variable "command" {
  description = "The command to run in the container"
  type        = list(string)
  default     = []
}

variable "args" {
  description = "The arguments to pass to the command"
  type        = list(string)
  default     = []
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
  default     = { cpu = "100m", memory = "128Mi" }
}

variable "resource_requests" {
  description = "Resource requests for the container"
  type        = map(string)
  default     = { cpu = "300m", memory = "384Mi" }

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

variable "health_probe_exec_command" {
  description = "The command to execute"
  default     = ["echo", "ok"]
}

variable "ingress_host" {
  description = "The host for the ingress"
  type        = string
  default     = ""
}

variable "inject_otlp" {
  description = "Flag to inject OpenTelemetry"
  type        = bool
  default     = true
}

variable "min_replicas" {
  description = "Minimum number of replicas for the deployment"
  type        = number
  default     = 2
}

variable "max_replicas" {
  description = "Maximum number of replicas for the deployment"
  type        = number
  default     = 8
}

variable "run_as_root" {
  description = "Run the container as root"
  type        = bool
  default     = false
}

variable "node_selector" {
  description = "Node selector for Kubernetes deployment"
  type        = map(string)
  nullable    = true
}
