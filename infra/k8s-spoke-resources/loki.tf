locals {
  loki_service_account_name         = "loki"
  loki_storage_chunk_container_name = "loki-chunk"
  loki_storage_ruler_container_name = "loki-ruler"
  loki_canary_service               = "loki-canary.${kubernetes_namespace.loki.metadata.0.name}.svc.cluster.local"
  loki_gateway_service              = "loki-gateway.${kubernetes_namespace.loki.metadata.0.name}.svc.cluster.local"
  loki_distributor_service          = "loki-distributor.${kubernetes_namespace.loki.metadata.0.name}.svc.cluster.local"
  loki_ingester_service             = "loki-ingester.${kubernetes_namespace.loki.metadata.0.name}.svc.cluster.local"
  loki_query_frontend_service       = "loki-query-frontend.${kubernetes_namespace.loki.metadata.0.name}.svc.cluster.local"
  loki_querier_service              = "loki-querier.${kubernetes_namespace.loki.metadata.0.name}.svc.cluster.local"
}

resource "azurerm_resource_group" "loki" {
  location = var.location
  name     = "${module.convention.resource_name}-loki"

  tags = var.tags
}

resource "kubernetes_namespace" "loki" {
  metadata {
    name = "loki"

    labels = {
      istio-injection = "enabled"
      provisioned_by  = "terraform"
    }
  }
}

resource "kubernetes_manifest" "loki_peer_authentication" {

  manifest = {
    apiVersion = "security.istio.io/v1beta1"
    kind       = "PeerAuthentication"
    metadata = {
      name      = "default"
      namespace = kubernetes_namespace.loki.metadata[0].name
    }
    spec = {
      mtls = {
        mode = "STRICT"
      }
    }
  }
}

resource "azuread_application" "loki" {
  #checkov:skip=CKV_AZURE_249  :  Ensure Azure GitHub Actions OIDC trust policy is configured securely
  display_name = "${var.env}-loki"
}

resource "azuread_service_principal" "loki" {
  client_id = azuread_application.loki.client_id
}

resource "azuread_application_federated_identity_credential" "loki" {
  application_id = azuread_application.loki.id
  display_name   = "${var.env}-loki-credential"

  audiences = ["api://AzureADTokenExchange"]
  issuer    = data.azurerm_kubernetes_cluster.m8t.oidc_issuer_url
  subject   = "system:serviceaccount:${kubernetes_namespace.loki.metadata[0].name}:${local.loki_service_account_name}"
}

resource "azurerm_storage_account" "loki" {

  #checkov:skip=CKV_AZURE_244  : Avoid the use of local users for Azure Storage unless necessary  
  #checkov:skip=CKV_AZURE_33   : Ensure Storage logging is enabled for Queue service for read, write and delete requests
  #checkov:skip=CKV2_AZURE_33  : Ensure storage account is configured with private endpoint         
  #checkov:skip=CKV2_AZURE_41  : Ensure storage account is configured with SAS expiration policy
  #checkov:skip=CKV2_AZURE_40  : Ensure storage account is not configured with Shared Key authorization      
  #checkov:skip=CKV2_AZURE_1   : Ensure storage for critical data are encrypted with Customer Managed Key
  #checkov:skip=CKV_AZURE_206  :  Ensure that Storage Accounts use replication

  depends_on = [azurerm_resource_group.loki]

  name                     = "${module.convention.resource_name_without_delimiter}loki"
  resource_group_name      = azurerm_resource_group.loki.name
  location                 = var.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"

  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = true
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "loki_storage" {

  principal_id         = azuread_service_principal.loki.object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.loki.id
}

resource "azurerm_private_endpoint" "loki_storage" {
  name                = "lokistoragepep"
  location            = var.location
  resource_group_name = azurerm_resource_group.loki.name

  subnet_id = data.azurerm_subnet.resources.id

  private_dns_zone_group {
    name                 = "lokistoragepep-dzg"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.blob.id]
  }


  private_service_connection {
    name                           = "lokistoragepep-cnx"
    private_connection_resource_id = azurerm_storage_account.loki.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = var.tags
}

resource "time_sleep" "wait_30_seconds_after_loki_storage_pep" {
  depends_on      = [azurerm_private_endpoint.loki_storage]
  create_duration = "30s"
}

resource "azurerm_storage_container" "loki_chunk" {

  #checkov:skip=CKV2_AZURE_21 : Ensure Storage logging is enabled for Blob service for read requests

  depends_on            = [time_sleep.wait_30_seconds_after_loki_storage_pep]
  name                  = local.loki_storage_chunk_container_name
  storage_account_id    = azurerm_storage_account.loki.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "loki_ruler" {

  #checkov:skip=CKV2_AZURE_21 : Ensure Storage logging is enabled for Blob service for read requests

  depends_on            = [time_sleep.wait_30_seconds_after_loki_storage_pep]
  name                  = local.loki_storage_ruler_container_name
  storage_account_id    = azurerm_storage_account.loki.id
  container_access_type = "private"
}

resource "helm_release" "loki" {
  depends_on = [
    helm_release.prometheus,
    kubernetes_namespace.loki,
    azurerm_storage_container.loki_chunk,
    azurerm_storage_container.loki_ruler,
    azurerm_role_assignment.loki_storage,
    kubernetes_manifest.loki_peer_authentication
  ]

  name       = "loki"
  namespace  = kubernetes_namespace.loki.metadata[0].name
  chart      = "loki"
  repository = "https://grafana.github.io/helm-charts"
  version    = var.loki_helmchart_version

  values = [
    <<EOF
loki:
  appProtocol:
    grpc: "tcp"
  podLabels:
    azure.workload.identity/use: "true"
  schemaConfig:
    configs:
      - from: "2024-04-01"
        store: tsdb
        object_store: azure
        schema: v13
        index:
          prefix: loki_index_
          period: 24h
  storage_config:
    azure:
      account_name: ${azurerm_storage_account.loki.name}
      container_name: ${local.loki_storage_chunk_container_name}
      use_federated_token: true
  ingester:
    chunk_encoding: snappy
  pattern_ingester:
    enabled: true
  limits_config:
    allow_structured_metadata: true
    volume_enabled: true
    retention_period: 672h
  compactor:
    retention_enabled: true
    delete_request_store: azure
  querier:
    max_concurrent: 3
  storage:
    type: azure
    bucketNames:
      chunks: ${local.loki_storage_chunk_container_name}
      ruler: ${local.loki_storage_ruler_container_name}
    azure:
      account_name: ${azurerm_storage_account.loki.name}
      use_federated_token: true

serviceAccount:
  name: ${local.loki_service_account_name}
  annotations:
    azure.workload.identity/client-id: "${azuread_application.loki.client_id}"
  labels:
    azure.workload.identity/use: "true"

deploymentMode: Distributed

ingester:
  appProtocol:
    grpc: "tcp"
  replicas: 3
  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
  tolerations:
    - key: kubernetes.azure.com/scalesetpriority
      operator: Equal
      value: spot
      effect: NoSchedule
  zoneAwareReplication:
    enabled: false

querier:
  appProtocol:
    grpc: "tcp"
  replicas: 3
  maxUnavailable: 2
  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
  tolerations:
    - key: kubernetes.azure.com/scalesetpriority
      operator: Equal
      value: spot
      effect: NoSchedule

queryFrontend:
  appProtocol:
    grpc: "tcp"
  replicas: 3
  maxUnavailable: 1
  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
  tolerations:
    - key: kubernetes.azure.com/scalesetpriority
      operator: Equal
      value: spot
      effect: NoSchedule

queryScheduler:
  appProtocol:
    grpc: "tcp"
  replicas: 1
  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
  tolerations:
    - key: kubernetes.azure.com/scalesetpriority
      operator: Equal
      value: spot
      effect: NoSchedule

distributor:
  appProtocol:
    grpc: "tcp"
  replicas: 3
  maxUnavailable: 2
  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
  tolerations:
    - key: kubernetes.azure.com/scalesetpriority
      operator: Equal
      value: spot
      effect: NoSchedule

compactor:
  appProtocol:
    grpc: "tcp"
  replicas: 1
  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
  tolerations:
    - key: kubernetes.azure.com/scalesetpriority
      operator: Equal
      value: spot
      effect: NoSchedule

indexGateway:
  appProtocol:
    grpc: "tcp"
  replicas: 4
  maxUnavailable: 1
  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
  tolerations:
    - key: kubernetes.azure.com/scalesetpriority
      operator: Equal
      value: spot
      effect: NoSchedule

ruler:
  enabled: false

gateway:
  enabled: true
  replicas: 4

  service:
    type: ClusterIP

  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
  tolerations:
    - key: kubernetes.azure.com/scalesetpriority
      operator: Equal
      value: spot
      effect: NoSchedule

lokiCanary:
  enabled: true
  push: true

  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
  tolerations:
    - key: kubernetes.azure.com/scalesetpriority
      operator: Equal
      value: spot
      effect: NoSchedule

chunksCache:
  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
  tolerations:
    - key: kubernetes.azure.com/scalesetpriority
      operator: Equal
      value: spot
      effect: NoSchedule

resultsCache:
  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
  tolerations:
    - key: kubernetes.azure.com/scalesetpriority
      operator: Equal
      value: spot
      effect: NoSchedule

minio:
  enabled: false

backend:
  replicas: 0
read:
  replicas: 0
write:
  replicas: 0

singleBinary:
  replicas: 0
EOF
  ]
}

resource "helm_release" "promtail" {
  depends_on = [
    helm_release.loki
  ]

  name       = "promtail"
  namespace  = kubernetes_namespace.loki.metadata[0].name
  chart      = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  version    = var.promtail_helmchart_version

  values = [
    <<EOF
extraVolumes:
  - name: positions
    emptyDir: {}
extraVolumeMounts:
  - name: positions
    mountPath: /tmp/promtail
config:
  clients:
    - url: http://${local.loki_gateway_service}/loki/api/v1/push
      tenant_id: default
  positions:
    filename: /tmp/promtail/positions.yaml
  scrape_configs:
    - job_name: kubernetes-pods
      kubernetes_sd_configs:
        - role: pod
      relabel_configs:
        - source_labels: [__meta_kubernetes_pod_label_app]
          target_label: job
        - action: labelmap
          regex: __meta_kubernetes_pod_label_(.+)
        - source_labels: [__meta_kubernetes_namespace]
          target_label: namespace
        - source_labels: [__meta_kubernetes_pod_name]
          target_label: pod
tolerations:
  - key: kubernetes.azure.com/scalesetpriority
    operator: Equal
    value: spot
    effect: NoSchedule
  - key: CriticalAddonsOnly
    operator: Exists
    effect: NoSchedule
EOF
  ]
}

resource "kubectl_manifest" "loki_otlp" {
  depends_on = [
    helm_release.loki,
    kubernetes_manifest.loki_peer_authentication
  ]

  yaml_body = <<YAML
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: otlp-loki
  namespace: ${kubernetes_namespace.loki.metadata[0].name}
spec:
  mode: deployment
        
  resources:
    requests:
      cpu: "50m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"
  config:
    receivers:
      prometheus:
        config:
          scrape_configs:
            - job_name: "loki-canary"
              scrape_interval: 30s
              metrics_path: /metrics
              static_configs:
                - targets:
                    - "${local.loki_canary_service}:3500"

            - job_name: "loki-distributor"
              scrape_interval: 30s
              metrics_path: /metrics
              static_configs:
                - targets:
                    - "${local.loki_distributor_service}:3100"

            - job_name: "loki-ingester"
              scrape_interval: 30s
              metrics_path: /metrics
              static_configs:
                - targets:
                    - "${local.loki_ingester_service}:3100"

            - job_name: "loki-querier"
              scrape_interval: 30s
              metrics_path: /metrics
              static_configs:
                - targets:
                    - "${local.loki_querier_service}:3100"

            - job_name: "loki-query-frontend"
              scrape_interval: 30s
              metrics_path: /metrics
              static_configs:
                - targets:
                    - "${local.loki_query_frontend_service}:3100"

    processors:
      batch: {}
    exporters:
      prometheusremotewrite:
        endpoint: "http://${local.prometheus_server_service}/api/v1/write"
    service:
      pipelines:
        metrics:
          receivers: [prometheus]
          processors: [batch]
          exporters: [prometheusremotewrite]
YAML

  ignore_fields = [
    "metadata.annotations",
    "metadata.labels",
    "metadata.finalizers",
    "status",
    "spec",
  ]
}

