locals {
  otlp_namespaces = [
    kubernetes_namespace.app.metadata[0].name,
    kubernetes_namespace.keycloak.metadata[0].name
  ]
}

resource "kubernetes_secret" "grafana_cloud_config" {
  for_each = toset(local.otlp_namespaces)

  metadata {
    name      = "grafana-cloud-config"
    namespace = each.value
  }
  data = {
    password = data.terraform_remote_state.k8s_obs.outputs.grafana_config.global.auth
  }
}


resource "kubectl_manifest" "otlp" {
  for_each = toset(local.otlp_namespaces)

  depends_on = [kubernetes_secret.grafana_cloud_config]

  yaml_body = yamlencode({
    apiVersion = "opentelemetry.io/v1beta1"
    kind       = "OpenTelemetryCollector"
    metadata = {
      name      = "otlp-app-sidecar"
      namespace = each.value
    }
    spec = {
      mode = "sidecar"
      args = {
        feature-gates = "+service.profilesSupport"
      }
      resources = {
        requests = {
          cpu    = var.otlp.resources.requests.cpu
          memory = var.otlp.resources.requests.memory
        }
        limits = {
          cpu    = var.otlp.resources.limits.cpu
          memory = var.otlp.resources.limits.memory
        }
      }
      env = [
        {
          name = "GRAFANA_CLOUD_PASSWORD"
          valueFrom = {
            secretKeyRef = {
              name = kubernetes_secret.grafana_cloud_config[each.value].metadata[0].name
              key  = "password"
            }
          }
        }
      ]
      config = {
        extensions = {
          "basicauth/otlp" = {
            client_auth = {
              username = data.terraform_remote_state.k8s_obs.outputs.grafana_config.otlp.username
              password = "$${GRAFANA_CLOUD_PASSWORD}"
            }
          },
          "basicauth/loki" = {
            client_auth = {
              username = data.terraform_remote_state.k8s_obs.outputs.grafana_config.loki.username
              password = "$${GRAFANA_CLOUD_PASSWORD}"
            }
          },
          "basicauth/prometheus" = {
            client_auth = {
              username = data.terraform_remote_state.k8s_obs.outputs.grafana_config.prometheus.username
              password = "$${GRAFANA_CLOUD_PASSWORD}"
            }
          }
        }
        receivers = {
          otlp = {
            protocols = {
              grpc = {}
            }
          }
        }
        processors = {
          batch = {}
          k8sattributes = {
            passthrough = true
          }
          attributes = {
            actions = [
              {
                key    = "environment"
                value  = var.env
                action = "upsert"
              }
            ]
          }
        }
        exporters = {
          "loki/grafana" = {
            endpoint = data.terraform_remote_state.k8s_obs.outputs.grafana_config.loki.endpoint
            auth = {
              authenticator = "basicauth/loki"
            }
          }
          "prometheusremotewrite/grafana" = {
            endpoint = data.terraform_remote_state.k8s_obs.outputs.grafana_config.prometheus.endpoint
            auth = {
              authenticator = "basicauth/prometheus"
            }
            external_labels = {
              cluster            = data.terraform_remote_state.k8s_obs.outputs.grafana_config.global.cluster_name
              "k8s.cluster.name" = data.terraform_remote_state.k8s_obs.outputs.grafana_config.global.cluster_name
            }
          }
          "otlphttp/grafana" = {
            endpoint = data.terraform_remote_state.k8s_obs.outputs.grafana_config.otlp.endpoint
            auth = {
              authenticator = "basicauth/otlp"
            }
          }
          debug = {
            verbosity = "detailed"
          }
        }
        service = {
          extensions = [
            "basicauth/otlp",
            "basicauth/loki",
            "basicauth/prometheus"
          ]
          pipelines = {
            metrics = {
              receivers  = ["otlp"]
              processors = ["attributes", "batch", "k8sattributes"]
              exporters  = ["prometheusremotewrite/grafana"]
            }
            logs = {
              receivers  = ["otlp"]
              processors = ["attributes", "batch", "k8sattributes"]
              exporters  = ["loki/grafana"]
            }
            traces = {
              receivers  = ["otlp"]
              processors = ["attributes", "batch", "k8sattributes"]
              exporters  = ["otlphttp/grafana"]
            }
            profiles = {
              receivers = ["otlp"]
              exporters = ["otlphttp/grafana"]
            }
          }
        }
      }
    }
  })

  ignore_fields = [
    "metadata.annotations",
    "metadata.labels",
    "metadata.finalizers",
    "status",
    "spec",
  ]
}
