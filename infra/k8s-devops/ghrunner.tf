locals {
  formatted_github_private_key = format("-----BEGIN RSA PRIVATE KEY-----\n%s\n-----END RSA PRIVATE KEY-----", replace(var.gh_runner_app_private_key, " ", ""))
}


resource "kubernetes_namespace" "ghrunner" {
  metadata {
    name = "ghrunner"

    labels = {
      istio-injection = "enabled"
      provisioned_by  = "terraform"
    }
  }
}

resource "kubernetes_manifest" "ghrunner_peer_authentication" {

  manifest = {
    apiVersion = "security.istio.io/v1beta1"
    kind       = "PeerAuthentication"
    metadata = {
      name      = "default"
      namespace = kubernetes_namespace.ghrunner.metadata[0].name
    }
    spec = {
      mtls = {
        mode = "STRICT"
      }
    }
  }
}


module "ghrunner" {

  depends_on = [
    kubernetes_namespace.ghrunner,
    kubernetes_manifest.ghrunner_peer_authentication
  ]

  source = "../modules/k8s-deploy"

  name                              = "ghrunner"
  env                               = var.env
  project_name                      = var.project_name
  namespace                         = kubernetes_namespace.ghrunner.metadata[0].name
  workload_identity_oidc_issuer_url = data.azurerm_kubernetes_cluster.m8t.oidc_issuer_url
  environment                       = var.env

  node_selector = null

  resource_requests = {
    cpu    = "100m"
    memory = "128Mi"
  }

  resource_limits = {
    cpu    = "1"
    memory = "2Gi"
  }

  min_replicas = 4
  max_replicas = 4

  inject_otlp = false

  env_vars = {
    RUNNER_SCOPE        = "repo"
    REPO_URL            = "https://github.com/using-system/m8te.ai"
    DISABLE_AUTO_UPDATE = "true"
    APP_ID              = var.gh_runner_app_id
    APP_PRIVATE_KEY     = local.formatted_github_private_key
    LABELS              = var.gh_runner_labels
    RUN_AS_ROOT         = "true"
  }

  default_image = var.gh_runner_image

  run_as_root               = true
  read_only_root_filesystem = false

  health_probe_transport_mode = "exec"

}
