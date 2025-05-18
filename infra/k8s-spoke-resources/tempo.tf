locals {
  tempo_service_account_name   = "tempo"
  tempo_traces_container_name  = "tempo-traces"
  tempo_distributor_service    = "tempo-distributor.${kubernetes_namespace.tempo.metadata.0.name}.svc.cluster.local"
  tempo_compactor_service      = "tempo-compactor.${kubernetes_namespace.tempo.metadata.0.name}.svc.cluster.local"
  tempo_ingester_service       = "tempo-ingester.${kubernetes_namespace.tempo.metadata.0.name}.svc.cluster.local"
  tempo_querier_service        = "tempo-querier.${kubernetes_namespace.tempo.metadata.0.name}.svc.cluster.local"
  tempo_query_frontend_service = "tempo-query-frontend.${kubernetes_namespace.tempo.metadata.0.name}.svc.cluster.local"
  tempo_gateway_service        = "tempo-gateway.${kubernetes_namespace.tempo.metadata.0.name}.svc.cluster.local"
}

resource "azurerm_resource_group" "tempo" {
  location = var.location
  name     = "${module.convention.resource_name}-tempo"

  tags = var.tags
}

resource "kubernetes_namespace" "tempo" {
  metadata {
    name = "tempo"

    labels = {
      istio-injection = "enabled"
      provisioned_by  = "terraform"
    }
  }
}

resource "kubernetes_manifest" "tempo_peer_authentication" {

  manifest = {
    apiVersion = "security.istio.io/v1beta1"
    kind       = "PeerAuthentication"
    metadata = {
      name      = "default"
      namespace = kubernetes_namespace.tempo.metadata[0].name
    }
    spec = {
      mtls = {
        mode = "STRICT"
      }
    }
  }
}


resource "azuread_application" "tempo" {
  #checkov:skip=CKV_AZURE_249  :  Ensure Azure GitHub Actions OIDC trust policy is configured securely
  display_name = "${var.env}-tempo"
}

resource "azuread_service_principal" "tempo" {
  client_id = azuread_application.tempo.client_id
}

resource "azuread_application_federated_identity_credential" "tempo" {
  application_id = azuread_application.tempo.id
  display_name   = "${var.env}-tempo-credential"

  audiences = ["api://AzureADTokenExchange"]
  issuer    = data.azurerm_kubernetes_cluster.m8t.oidc_issuer_url
  subject   = "system:serviceaccount:${kubernetes_namespace.tempo.metadata[0].name}:${local.tempo_service_account_name}"
}

resource "azurerm_storage_account" "tempo" {

  #checkov:skip=CKV_AZURE_244  : Avoid the use of local users for Azure Storage unless necessary  
  #checkov:skip=CKV_AZURE_33   : Ensure Storage logging is enabled for Queue service for read, write and delete requests
  #checkov:skip=CKV2_AZURE_33  : Ensure storage account is configured with private endpoint         
  #checkov:skip=CKV2_AZURE_41  : Ensure storage account is configured with SAS expiration policy
  #checkov:skip=CKV2_AZURE_40  : Ensure storage account is not configured with Shared Key authorization      
  #checkov:skip=CKV2_AZURE_1   : Ensure storage for critical data are encrypted with Customer Managed Key
  #checkov:skip=CKV_AZURE_206  :  Ensure that Storage Accounts use replication

  depends_on = [azurerm_resource_group.tempo]

  name                     = "${module.convention.resource_name_without_delimiter}tempo"
  resource_group_name      = azurerm_resource_group.tempo.name
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

resource "azurerm_role_assignment" "tempo_storage" {

  principal_id         = azuread_service_principal.tempo.object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.tempo.id
}

resource "azurerm_private_endpoint" "tempo_storage" {
  name                = "tempostoragepep"
  location            = var.location
  resource_group_name = azurerm_resource_group.tempo.name

  subnet_id = data.azurerm_subnet.resources.id

  private_dns_zone_group {
    name                 = "tempostoragepep-dzg"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.blob.id]
  }


  private_service_connection {
    name                           = "tempostoragepep-cnx"
    private_connection_resource_id = azurerm_storage_account.tempo.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = var.tags
}

resource "time_sleep" "wait_30_seconds_after_tempo_storage_pep" {
  depends_on      = [azurerm_private_endpoint.tempo_storage]
  create_duration = "30s"
}

resource "azurerm_storage_container" "tempo_traces" {

  #checkov:skip=CKV2_AZURE_21 : Ensure Storage logging is enabled for Blob service for read requests

  depends_on            = [time_sleep.wait_30_seconds_after_tempo_storage_pep]
  name                  = local.tempo_traces_container_name
  storage_account_id    = azurerm_storage_account.tempo.id
  container_access_type = "private"
}

resource "helm_release" "tempo" {
  depends_on = [
    helm_release.prometheus,
    kubernetes_namespace.tempo,
    azurerm_storage_container.tempo_traces,
    azurerm_role_assignment.tempo_storage,
    kubernetes_manifest.tempo_peer_authentication
  ]

  name       = "tempo"
  namespace  = kubernetes_namespace.tempo.metadata[0].name
  chart      = "tempo-distributed"
  repository = "https://grafana.github.io/helm-charts"
  version    = var.tempo_helmchart_version

  values = [
    <<EOF
storage:
  trace:
    backend: azure
    azure:
      storage_account_name: ${azurerm_storage_account.tempo.name}
      container_name: ${local.tempo_traces_container_name}
      use_federated_token: true

serviceAccount:
  create: true
  name: ${local.tempo_service_account_name}
  automountServiceAccountToken: true
  annotations:
    azure.workload.identity/client-id: "${azuread_application.tempo.client_id}"
    azure.workload.identity/tenant-id: "${data.azurerm_client_config.current.tenant_id}"
    azure.workload.identity/audience: "api://AzureADTokenExchange"
  labels:
    azure.workload.identity/use: "true"

tempo:
  podLabels:
    azure.workload.identity/use: "true"
  memberlist:
    appProtocol: "tcp"

traces:
  otlp:
    grpc:
      enabled: true

ingester:
  appProtocol:
    grpc: "tcp"
  extraEnv:
    - name: GOMEMLIMIT
      value: "3GiB"
    - name: GOGC
      value: "100"
  resources:
    requests:
      cpu: "500m"
      memory: "2Gi"
    limits:
      cpu: "1"
      memory: "4Gi"
  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
  tolerations:
    - key: kubernetes.azure.com/scalesetpriority
      operator: Equal
      value: spot
      effect: NoSchedule

  podAnnotations:
    traffic.sidecar.istio.io/excludeOutboundPorts: "9095"
    traffic.sidecar.istio.io/excludeInboundPorts: "9095"



distributor:
  appProtocol:
    grpc: "tcp"
  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
  tolerations:
    - key: kubernetes.azure.com/scalesetpriority
      operator: Equal
      value: spot
      effect: NoSchedule

  podAnnotations:
    traffic.sidecar.istio.io/excludeOutboundPorts: "9095"
    traffic.sidecar.istio.io/excludeInboundPorts: "9095"

compactor:
  appProtocol:
    grpc: "tcp"
  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
  tolerations:
    - key: kubernetes.azure.com/scalesetpriority
      operator: Equal
      value: spot
      effect: NoSchedule

  podAnnotations:
    traffic.sidecar.istio.io/excludeOutboundPorts: "9095"
    traffic.sidecar.istio.io/excludeInboundPorts: "9095"

querier:
  appProtocol:
    grpc: "tcp"
  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
  tolerations:
    - key: kubernetes.azure.com/scalesetpriority
      operator: Equal
      value: spot
      effect: NoSchedule

  podAnnotations:
    traffic.sidecar.istio.io/excludeOutboundPorts: "9095"
    traffic.sidecar.istio.io/excludeInboundPorts: "9095"

queryFrontend:
  appProtocol:
    grpc: "tcp"
  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
  tolerations:
    - key: kubernetes.azure.com/scalesetpriority
      operator: Equal
      value: spot
      effect: NoSchedule
  podAnnotations:
    traffic.sidecar.istio.io/excludeOutboundPorts: "9095"
    traffic.sidecar.istio.io/excludeInboundPorts: "9095"

gateway:
  enabled: true

  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
  tolerations:
    - key: kubernetes.azure.com/scalesetpriority
      operator: Equal
      value: spot
      effect: NoSchedule
  podAnnotations:
    traffic.sidecar.istio.io/excludeOutboundPorts: "9095"
    traffic.sidecar.istio.io/excludeInboundPorts: "9095"

metricsGenerator:
  enabled: true
  config:
    remote_write:
      - name: prometheus
        url: "http://${local.prometheus_server_service}/api/v1/write"
        send_exemplars: true

  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
  tolerations:
    - key: kubernetes.azure.com/scalesetpriority
      operator: Equal
      value: spot
      effect: NoSchedule

  podAnnotations:
    traffic.sidecar.istio.io/excludeOutboundPorts: "9095"
    traffic.sidecar.istio.io/excludeInboundPorts: "9095"

memcached:

  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
  tolerations:
    - key: kubernetes.azure.com/scalesetpriority
      operator: Equal
      value: spot
      effect: NoSchedule

minio:
  enabled: false

adminApi:
  enabled: false
EOF
  ]
}

resource "kubectl_manifest" "tempo_otlp" {
  depends_on = [
    helm_release.tempo,
    kubernetes_manifest.tempo_peer_authentication
  ]

  yaml_body = <<YAML
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: otlp-tempo
  namespace: ${kubernetes_namespace.tempo.metadata[0].name}
spec:
  mode: deployment

  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot

  tolerations:
    - key: kubernetes.azure.com/scalesetpriority
      operator: Equal
      value: spot
      effect: NoSchedule
        
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

            - job_name: "tempo-compactor"
              scrape_interval: 30s
              metrics_path: /metrics
              static_configs:
                - targets:
                    - "${local.tempo_compactor_service}:3100"

            - job_name: "tempo-distributor"
              scrape_interval: 30s
              metrics_path: /metrics
              static_configs:
                - targets:
                    - "${local.tempo_distributor_service}:3100"

            - job_name: "tempo-ingester"
              scrape_interval: 30s
              metrics_path: /metrics
              static_configs:
                - targets:
                    - "${local.tempo_ingester_service}:3100"

            - job_name: "tempo-querier"
              scrape_interval: 30s
              metrics_path: /metrics
              static_configs:
                - targets:
                    - "${local.tempo_querier_service}:3100"

            - job_name: "tempo-query-frontend"
              scrape_interval: 30s
              metrics_path: /metrics
              static_configs:
                - targets:
                    - "${local.tempo_query_frontend_service}:3100"

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
