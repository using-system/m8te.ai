resource "kubernetes_namespace" "arc" {
  metadata {
    name = "arc"

    labels = {
      provisioned_by = "terraform"
    }
  }
}

resource "helm_release" "arc_systems" {
  depends_on = [
    kubernetes_namespace.arc
  ]

  name       = "arc-systems"
  namespace  = kubernetes_namespace.arc.metadata[0].name
  chart      = "gha-runner-scale-set-controller"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  version    = var.gha_runner_scale_set_controller_helmchart_version

  values = [
    yamlencode({
    })
  ]
}

resource "kubernetes_secret" "github_runner_config" {

  depends_on = [kubernetes_namespace.arc]

  metadata {
    name      = "github-config"
    namespace = kubernetes_namespace.arc.metadata[0].name
  }

  data = {
    github_app_id              = var.gh_runner_app_id
    github_app_installation_id = var.gh_runner_app_installation_id
    github_app_private_key     = local.formatted_github_private_key
  }
}

resource "helm_release" "arc_runners" {
  depends_on = [
    helm_release.arc_systems,
    kubernetes_secret.github_runner_config,
  ]

  name       = "arc-${var.env}-runners"
  namespace  = kubernetes_namespace.arc.metadata[0].name
  chart      = "gha-runner-scale-set"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  version    = var.gha_runner_scale_set_helmchart_version

  values = [
    yamlencode({
      githubConfigUrl    = var.gh_runner_repo_url
      githubConfigSecret = kubernetes_secret.github_runner_config.metadata[0].name
      template = {
        spec = {
          containers = [
            {
              name    = "runner"
              image   = "${var.gh_runner_image}"
              command = ["/home/runner/run.sh"]
            }
          ]
        }
      }
    })
  ]
}
