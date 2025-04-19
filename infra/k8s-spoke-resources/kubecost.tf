/*locals {
  kubecost_host = "${var.ingress_prefix}cost.${var.dns_zone_name}"
}

resource "kubernetes_namespace" "kubecost" {
  metadata {
    name = "kubecost"

    labels = {
      istio-injection = "enabled"
      provisioned_by  = "terraform"
    }
  }
}

resource "kubernetes_manifest" "kubecost_peer_authentication" {

  manifest = {
    apiVersion = "security.istio.io/v1beta1"
    kind       = "PeerAuthentication"
    metadata = {
      name      = "default"
      namespace = kubernetes_namespace.kubecost.metadata[0].name
    }
    spec = {
      mtls = {
        mode = "STRICT"
      }
    }
  }
}

resource "helm_release" "kubecost" {
  depends_on = [
    helm_release.prometheus,
    kubernetes_namespace.kubecost,
    kubernetes_manifest.kubecost_peer_authentication
  ]

  name       = "kubecost"
  namespace  = kubernetes_namespace.kubecost.metadata[0].name
  chart      = "cost-analyzer"
  repository = "https://kubecost.github.io/cost-analyzer/"
  version    = var.kubecost_helmchart_version

  values = [
    <<EOF
nodeSelector:
  "kubernetes.azure.com/scalesetpriority": "spot"
tolerations:
  - key: "kubernetes.azure.com/scalesetpriority"
    operator: "Equal"
    value: "spot"
    effect: "NoSchedule"

global:
  prometheus:
    enabled: true
    fqdn: http://${local.thanos_query_service}:9090
    insecureSkipVerify: true
  grafana:
    enabled: false 
    scheme: http
    domainName: grafana.grafana.svc.cluster.local
    proxy: false

forecasting:
  nodeSelector:
    "kubernetes.azure.com/scalesetpriority": "spot"
  tolerations:
    - key: "kubernetes.azure.com/scalesetpriority"
      operator: "Equal"
      value: "spot"
      effect: "NoSchedule"    
EOF
  ]
}


resource "kubectl_manifest" "otlp_kubecost" {
  yaml_body = <<YAML
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: otlp-kubecost
  namespace: ${kubernetes_namespace.kubecost.metadata[0].name}
spec:
  mode: deployment
  config:
    receivers:
      prometheus:
        config:
          scrape_configs:
            - job_name: "kubecost"
              metrics_path: /metrics
              scrape_interval: 30s
              scheme: http
              static_configs:
                - targets:
                    ["kubecost-prometheus-server.kubecost.svc.cluster.local:80"]
    processors:
      batch: {}
    exporters:
      prometheusremotewrite:
        endpoint: "http://${local.thanos_store_service}:10901/api/v1/receive"
      debug: {}
    service:
      pipelines:
        metrics:
          receivers:
            - prometheus
          processors:
            - batch
          exporters:
            - debug
YAML

  ignore_fields = [
    "metadata.annotations",
    "metadata.labels",
    "metadata.finalizers",
    "status",
    "spec",
  ]
}

resource "kubernetes_manifest" "kubecost_http_route" {
  depends_on = [helm_release.kubecost]

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "kubecost-route"
      namespace = kubernetes_namespace.kubecost.metadata[0].name
    }
    spec = {
      parentRefs = [
        {
          name        = "gateway"
          namespace   = "istio-system"
          sectionName = "default"
        }
      ]
      hostnames = [local.kubecost_host]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]
          backendRefs = [
            {
              name = "kubecost-cost-analyzer"
              port = 9090
            }
          ]
        }
      ]
    }
  }
}

resource "azurerm_dns_a_record" "kubecost" {

  name                = "${var.ingress_prefix}cost"
  zone_name           = var.dns_zone_name
  resource_group_name = "${var.project_name}-hub-infra-we-dns"
  ttl                 = 300
  records             = [data.kubernetes_service.istio_gateway.status[0].load_balancer[0].ingress[0].ip]
}
*/
