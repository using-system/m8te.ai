resource "kubernetes_namespace" "vpa" {
  metadata {
    name = "vpa"

    labels = {
      istio-injection = "enabled"
      provisioned_by  = "terraform"
    }
  }
}

resource "kubernetes_manifest" "vpa_peer_authentication" {

  manifest = {
    apiVersion = "security.istio.io/v1beta1"
    kind       = "PeerAuthentication"
    metadata = {
      name      = "default"
      namespace = kubernetes_namespace.vpa.metadata[0].name
    }
    spec = {
      mtls = {
        mode = "STRICT"
      }
    }
  }
}

resource "kubernetes_cluster_role" "vpa" {
  metadata {
    name = "vpa-recommender"
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "replicationcontrollers", "events"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "statefulsets", "daemonsets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods", "nodes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["autoscaling.k8s.io"]
    resources = [
      "verticalpodautoscalers",
      "verticalpodautoscalers/status",
    ]
    verbs = [
      "get", "list", "watch",
      "patch", "update",
    ]
  }

  rule {
    api_groups = ["autoscaling.k8s.io"]
    resources  = ["verticalpodautoscalercheckpoints"]
    verbs = [
      "get", "list", "watch",
      "create", "update", "patch", "delete",
    ]
  }
}

resource "kubernetes_service_account" "vpa" {
  metadata {
    name      = "vpa"
    namespace = kubernetes_namespace.vpa.metadata[0].name
  }
}

resource "kubernetes_cluster_role_binding" "vpa" {
  metadata {
    name = "vpa-recommender-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.vpa.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.vpa.metadata[0].name
    namespace = kubernetes_service_account.vpa.metadata[0].namespace
  }
}


resource "kubernetes_deployment" "vpa" {

  depends_on = [kubernetes_cluster_role_binding.vpa]

  # checkov:skip=CKV_K8S_15   “Image Pull Policy should be Always” — we use IfNotPresent to save bandwidth in this controlled context
  # checkov:skip=CKV_K8S_29   “Apply security context to your pods, deployments and daemon_sets” — securityContext is applied at Pod spec level
  # checkov:skip=CKV_K8S_8    “Liveness Probe Should be Configured” — health of this controller is monitored externally
  # checkov:skip=CKV_K8S_28   “Minimize the admission of containers with the NET_RAW capability” — no NET_RAW usage in this container
  # checkov:skip=CKV_K8S_43   “Image should use digest” — we pin via explicit tag/version
  # checkov:skip=CKV_K8S_9    “Readiness Probe Should be Configured” — readiness not required for this non‑customer‑facing controller
  # checkov:skip=CKV_K8S_30   “Apply security context to your pods and containers” — securityContext at Pod level suffices

  metadata {
    name      = "vpa-recommender"
    namespace = kubernetes_namespace.vpa.metadata[0].name
    labels = {
      app = "vpa-recommender"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "vpa-recommender"
      }
    }

    template {
      metadata {
        labels = {
          app = "vpa-recommender"
        }
      }

      spec {

        node_selector = {
          "kubernetes.azure.com/scalesetpriority" = "spot"
        }

        toleration {
          key      = "kubernetes.azure.com/scalesetpriority"
          operator = "Equal"
          value    = "spot"
          effect   = "NoSchedule"
        }

        service_account_name = kubernetes_service_account.vpa.metadata[0].name

        security_context {
          run_as_non_root = true
          run_as_user     = 65534
        }

        container {
          name              = "recommender"
          image             = var.vpa_image
          image_pull_policy = "IfNotPresent"

          resources {
            limits = {
              cpu    = "200m"
              memory = "1000Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "500Mi"
            }
          }

          port {
            name           = "prometheus"
            container_port = 8942
            protocol       = "TCP"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "vpa" {

  depends_on = [kubernetes_deployment.vpa]

  metadata {
    name      = "vpa-recommender"
    namespace = kubernetes_namespace.vpa.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment.vpa.spec[0].template[0].metadata[0].labels["app"]
    }

    port {
      name        = "prometheus"
      port        = 8942
      target_port = 8942
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

resource "kubectl_manifest" "otlp_vpa" {

  depends_on = [kubernetes_service.vpa]

  yaml_body = <<YAML
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: otlp-vpa-recommender
  namespace: ${kubernetes_namespace.vpa.metadata[0].name}
spec:
  mode: deployment
  config:
    receivers:
      prometheus:
        config:
          scrape_configs:
            - job_name: "vpa-recommender"
              metrics_path: /metrics
              scrape_interval: 30s
              scheme: http
              static_configs:
                - targets:
                    ["vpa-recommender.vpa.svc.cluster.local:8942"]
    processors:
      batch: {}
      filter/vpa:
        metrics:
          include:
            match_type: regexp
            metric_names:
              - "^vpa_.*$"
    exporters:
      prometheusremotewrite:
        endpoint: "http://${local.prometheus_server_service}:80/api/v1/write"
    service:
      pipelines:
        metrics:
          receivers:
            - prometheus
          processors:
            - batch
          exporters:
            - prometheusremotewrite
YAML

  ignore_fields = [
    "metadata.annotations",
    "metadata.labels",
    "metadata.finalizers",
    "status",
    "spec",
  ]
}
