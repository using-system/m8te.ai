resource "kubernetes_namespace" "traefik" {
  metadata {
    name = "traefik"
  }
}

resource "helm_release" "traefik" {

  depends_on = [kubernetes_namespace.traefik]

  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = var.traefik_helmchart_version
  create_namespace = false
  namespace        = kubernetes_namespace.traefik.metadata[0].name
  values = [
    <<EOF
nodeSelector:
  "kubernetes.azure.com/scalesetpriority": "spot"
tolerations:
  - key: "kubernetes.azure.com/scalesetpriority"
    operator: "Equal"
    value: "spot"
    effect: "NoSchedule"

deployment:
  replicas: 1

providers:
  kubernetesIngress:
    enabled: true
  kubernetesGateway:
    enabled: false

service:
  type: LoadBalancer
EOF
  ]
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "traefik" {

  depends_on = [helm_release.traefik]

  metadata {
    name      = "hpa-traefik"
    namespace = kubernetes_namespace.traefik.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "traefik"
    }

    min_replicas = 4
    max_replicas = 8

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
  }
}
