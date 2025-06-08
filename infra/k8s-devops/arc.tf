locals {
  arc_runners_name = "arc-${var.env}-runners"

}
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
      metrics = {
        controllerManagerAddr = ":8080"
        listenerAddr          = ":8080"
        listenerEndpoint      = "/metrics"
      }
      podAnnotations = {
        "prometheus.io/scrape" = "true"
        "prometheus.io/port"   = "8080"
        "prometheus.io/path"   = "/metrics"
        "prometheus.io/scheme" = "http"
      }
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

  name       = local.arc_runners_name
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
              resources = {
                requests = {
                  cpu    = "300m"
                  memory = "512Mi"
                }
              }
            }
          ]
        }
      }
      listenerMetrics = {

        counters = {
          gha_started_jobs_total = {
            labels = [
              "repository",
              "organization",
              "enterprise",
              "job_name",
              "event_name",
            ]
          }
          gha_completed_jobs_total = {
            labels = [
              "repository",
              "organization",
              "enterprise",
              "job_name",
              "event_name",
              "job_result",
            ]
          }
        }

        gauges = {
          gha_assigned_jobs      = { labels = ["name", "namespace", "repository", "organization", "enterprise"] }
          gha_running_jobs       = { labels = ["name", "namespace", "repository", "organization", "enterprise"] }
          gha_registered_runners = { labels = ["name", "namespace", "repository", "organization", "enterprise"] }
          gha_busy_runners       = { labels = ["name", "namespace", "repository", "organization", "enterprise"] }
          gha_min_runners        = { labels = ["name", "namespace", "repository", "organization", "enterprise"] }
          gha_max_runners        = { labels = ["name", "namespace", "repository", "organization", "enterprise"] }
          gha_desired_runners    = { labels = ["name", "namespace", "repository", "organization", "enterprise"] }
          gha_idle_runners       = { labels = ["name", "namespace", "repository", "organization", "enterprise"] }
        }

        histograms = {
          gha_job_startup_duration_seconds = {
            labels = [
              "repository",
              "organization",
              "enterprise",
              "job_name",
              "event_name",
            ]
            buckets = [
              0.01, 0.05, 0.1, 0.5, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0,
              7.0, 8.0, 9.0, 10.0, 12.0, 15.0, 18.0, 20.0, 25.0, 30.0,
              40.0, 50.0, 60.0, 70.0, 80.0, 90.0, 100.0, 110.0, 120.0,
              150.0, 180.0, 210.0, 240.0, 300.0, 360.0, 420.0, 480.0,
              540.0, 600.0, 900.0, 1200.0, 1800.0, 2400.0, 3000.0, 3600.0,
            ]
          }

          gha_job_execution_duration_seconds = {
            labels = [
              "repository",
              "organization",
              "enterprise",
              "job_name",
              "event_name",
              "job_result",
            ]
            buckets = [
              0.01, 0.05, 0.1, 0.5, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0,
              7.0, 8.0, 9.0, 10.0, 12.0, 15.0, 18.0, 20.0, 25.0, 30.0,
              40.0, 50.0, 60.0, 70.0, 80.0, 90.0, 100.0, 110.0, 120.0,
              150.0, 180.0, 210.0, 240.0, 300.0, 360.0, 420.0, 480.0,
              540.0, 600.0, 900.0, 1200.0, 1800.0, 2400.0, 3000.0, 3600.0,
            ]
          }
        }
      }
      listenerTemplate = {
        metadata = {
          annotations = {
            "prometheus.io/scrape" = "true"
            "prometheus.io/port"   = "8080"
            "prometheus.io/path"   = "/metrics"
          }
        }
        spec = {
          containers = [
            {
              name = "listener"
            }
          ]
        }
      }
    })
  ]
}

