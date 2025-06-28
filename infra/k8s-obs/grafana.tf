resource "kubernetes_namespace" "grafana" {
  metadata {
    name = "grafana"

    labels = {
      provisioned_by = "terraform"
    }
  }

}

resource "kubernetes_secret" "grafana_cloud_config" {
  metadata {
    name      = "grafana-cloud-config"
    namespace = kubernetes_namespace.grafana.metadata[0].name
  }
  data = {
    password = var.grafana_auth
  }
}

# ServiceAccount for OpenTelemetry Collector
resource "kubernetes_service_account" "grafana_otlp_collector" {
  metadata {
    name      = "grafana-otlp-collector"
    namespace = kubernetes_namespace.grafana.metadata[0].name
  }
}

# ClusterRole for OpenTelemetry Collector
resource "kubernetes_cluster_role" "grafana_otlp_collector" {
  metadata {
    name = "grafana-otlp-collector"
  }

  rule {
    api_groups = [""]
    resources = [
      "nodes",
      "nodes/proxy",
      "services",
      "endpoints",
      "pods",
      "events",
      "namespaces",
      "namespaces/status",
      "pods/status",
      "replicationcontrollers",
      "replicationcontrollers/status",
      "resourcequotas"
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    non_resource_urls = ["/metrics"]
    verbs             = ["get"]
  }

  rule {
    api_groups = ["apps"]
    resources = [
      "daemonsets",
      "deployments",
      "replicasets",
      "statefulsets"
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions"]
    resources = [
      "daemonsets",
      "deployments",
      "replicasets"
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources = [
      "jobs",
      "cronjobs"
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources = [
      "horizontalpodautoscalers"
    ]
    verbs = ["get", "list", "watch"]
  }
}

# ClusterRoleBinding for OpenTelemetry Collector
resource "kubernetes_cluster_role_binding" "grafana_otlp_collector" {
  metadata {
    name = "grafana-otlp-collector"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.grafana_otlp_collector.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.grafana_otlp_collector.metadata[0].name
    namespace = kubernetes_namespace.grafana.metadata[0].name
  }
}

resource "kubectl_manifest" "grafana_otlp_deploy_collector" {
  depends_on = [
    helm_release.kube_state_metrics,
    helm_release.prometheus_node_exporter
  ]

  yaml_body = yamlencode({
    apiVersion = "opentelemetry.io/v1beta1"
    kind       = "OpenTelemetryCollector"
    metadata = {
      name      = "grafana-otlp-deploy-collector"
      namespace = kubernetes_namespace.grafana.metadata[0].name
    }
    spec = {
      mode           = "deployment"
      serviceAccount = kubernetes_service_account.grafana_otlp_collector.metadata[0].name
      nodeSelector   = var.node_selector
      tolerations    = local.tolerations_from_node_selector
      env = [
        {
          name = "GRAFANA_CLOUD_PASSWORD"
          valueFrom = {
            secretKeyRef = {
              name = kubernetes_secret.grafana_cloud_config.metadata[0].name
              key  = "password"
            }
          }
        }
      ]
      resources = {
        requests = {
          cpu    = "50m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
      config = {
        extensions = {
          "basicauth/loki" = {
            client_auth = {
              username = var.grafana_loki_username
              password = "$${GRAFANA_CLOUD_PASSWORD}"
            }
          },
          "basicauth/prometheus" = {
            client_auth = {
              username = var.grafana_prometheus_username
              password = "$${GRAFANA_CLOUD_PASSWORD}"
            }
          }
        }

        receivers = {
          k8s_events = {
            namespaces = []
          }

          prometheus = {
            config = {
              scrape_configs = [
                {
                  bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
                  job_name          = "integrations/kubernetes/cadvisor"
                  kubernetes_sd_configs = [
                    {
                      role = "node"
                    }
                  ]
                  relabel_configs = [
                    {
                      replacement  = "kubernetes.default.svc.cluster.local:443"
                      target_label = "__address__"
                    },
                    {
                      regex         = "(.+)"
                      replacement   = "/api/v1/nodes/$$${1}/proxy/metrics/cadvisor"
                      source_labels = ["__meta_kubernetes_node_name"]
                      target_label  = "__metrics_path__"
                    }
                  ]
                  metric_relabel_configs = [
                    {
                      source_labels = ["__name__"]
                      action        = "keep"
                      regex         = "container_cpu_cfs_periods_total|container_cpu_cfs_throttled_periods_total|container_cpu_usage_seconds_total|container_fs_reads_bytes_total|container_fs_reads_total|container_fs_writes_bytes_total|container_fs_writes_total|container_memory_cache|container_memory_rss|container_memory_swap|container_memory_working_set_bytes|container_network_receive_bytes_total|container_network_receive_packets_dropped_total|container_network_receive_packets_total|container_network_transmit_bytes_total|container_network_transmit_packets_dropped_total|container_network_transmit_packets_total|machine_memory_bytes"
                    }
                  ]
                  scheme = "https"
                  tls_config = {
                    ca_file              = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
                    insecure_skip_verify = false
                    server_name          = "kubernetes"
                  }
                },
                {
                  bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
                  job_name          = "integrations/kubernetes/kubelet"
                  kubernetes_sd_configs = [
                    {
                      role = "node"
                    }
                  ]
                  relabel_configs = [
                    {
                      replacement  = "kubernetes.default.svc.cluster.local:443"
                      target_label = "__address__"
                    },
                    {
                      regex         = "(.+)"
                      replacement   = "/api/v1/nodes/$$${1}/proxy/metrics"
                      source_labels = ["__meta_kubernetes_node_name"]
                      target_label  = "__metrics_path__"
                    }
                  ]
                  metric_relabel_configs = [
                    {
                      source_labels = ["__name__"]
                      action        = "keep"
                      regex         = "container_cpu_usage_seconds_total|kubelet_certificate_manager_client_expiration_renew_errors|kubelet_certificate_manager_client_ttl_seconds|kubelet_certificate_manager_server_ttl_seconds|kubelet_cgroup_manager_duration_seconds_bucket|kubelet_cgroup_manager_duration_seconds_count|kubelet_node_config_error|kubelet_node_name|kubelet_pleg_relist_duration_seconds_bucket|kubelet_pleg_relist_duration_seconds_count|kubelet_pleg_relist_interval_seconds_bucket|kubelet_pod_start_duration_seconds_bucket|kubelet_pod_start_duration_seconds_count|kubelet_pod_worker_duration_seconds_bucket|kubelet_pod_worker_duration_seconds_count|kubelet_running_container_count|kubelet_running_containers|kubelet_running_pod_count|kubelet_running_pods|kubelet_runtime_operations_errors_total|kubelet_runtime_operations_total|kubelet_server_expiration_renew_errors|kubelet_volume_stats_available_bytes|kubelet_volume_stats_capacity_bytes|kubelet_volume_stats_inodes|kubelet_volume_stats_inodes_used|kubernetes_build_info|namespace_workload_pod|rest_client_requests_total|storage_operation_duration_seconds_count|storage_operation_errors_total|volume_manager_total_volumes"
                    }
                  ]
                  scheme = "https"
                  tls_config = {
                    ca_file              = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
                    insecure_skip_verify = false
                    server_name          = "kubernetes"
                  }
                },
                {
                  job_name = "integrations/kubernetes/kube-state-metrics"
                  kubernetes_sd_configs = [
                    {
                      role = "pod"
                    }
                  ]
                  relabel_configs = [
                    {
                      action        = "keep"
                      regex         = "kube-state-metrics"
                      source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_name"]
                    }
                  ]
                  metric_relabel_configs = [
                    {
                      source_labels = ["__name__"]
                      action        = "keep"
                      regex         = "kube_daemonset.*|kube_deployment_metadata_generation|kube_deployment_spec_replicas|kube_deployment_status_observed_generation|kube_deployment_status_replicas_available|kube_deployment_status_replicas_updated|kube_horizontalpodautoscaler_spec_max_replicas|kube_horizontalpodautoscaler_spec_min_replicas|kube_horizontalpodautoscaler_status_current_replicas|kube_horizontalpodautoscaler_status_desired_replicas|kube_job.*|kube_namespace_status_phase|kube_node.*|kube_persistentvolumeclaim_resource_requests_storage_bytes|kube_pod_container_info|kube_pod_container_resource_limits|kube_pod_container_resource_requests|kube_pod_container_status_last_terminated_reason|kube_pod_container_status_restarts_total|kube_pod_container_status_waiting_reason|kube_pod_info|kube_pod_owner|kube_pod_start_time|kube_pod_status_phase|kube_pod_status_reason|kube_replicaset.*|kube_resourcequota|kube_statefulset.*"
                    }
                  ]
                },
                {
                  job_name = "integrations/node_exporter"
                  kubernetes_sd_configs = [
                    {
                      role = "pod"
                    }
                  ]
                  relabel_configs = [
                    {
                      action        = "keep"
                      regex         = "prometheus-node-exporter.*"
                      source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_name"]
                    },
                    {
                      action        = "replace"
                      source_labels = ["__meta_kubernetes_pod_node_name"]
                      target_label  = "instance"
                    },
                    {
                      action        = "replace"
                      source_labels = ["__meta_kubernetes_namespace"]
                      target_label  = "namespace"
                    }
                  ]
                  metric_relabel_configs = [
                    {
                      source_labels = ["__name__"]
                      action        = "keep"
                      regex         = "node_cpu.*|node_exporter_build_info|node_filesystem.*|node_memory.*|process_cpu_seconds_total|process_resident_memory_bytes"
                    }
                  ]
                }
              ]
            }
          }
        }

        processors = {
          batch = {}
          "resource/k8s_events" = {
            attributes = [
              {
                action = "insert"
                key    = "cluster"
                value  = var.grafana_cluster_name
              },
              {
                action = "insert"
                key    = "job"
                value  = "integrations/kubernetes/eventhandler"
              },
              {
                action = "insert"
                key    = "loki.resource.labels"
                value  = "job, cluster"
              }
            ]
          }
        }

        exporters = {
          "loki/grafana" = {
            endpoint = var.grafana_loki_push_url
            auth = {
              authenticator = "basicauth/loki"
            }
          }
          "prometheusremotewrite/grafana" = {
            endpoint = var.grafana_prometheus_push_url
            auth = {
              authenticator = "basicauth/prometheus"
            }
            external_labels = {
              cluster            = var.grafana_cluster_name
              "k8s.cluster.name" = var.grafana_cluster_name
            }
          }
        }

        service = {
          extensions = [
            "basicauth/loki",
            "basicauth/prometheus"
          ]
          pipelines = {
            metrics = {
              receivers  = ["prometheus"]
              processors = ["batch"]
              exporters  = ["prometheusremotewrite/grafana"]
            }
            logs = {
              receivers  = ["k8s_events"]
              processors = ["batch", "resource/k8s_events"]
              exporters  = ["loki/grafana"]
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
    "status"
  ]
}

resource "kubectl_manifest" "grafana_otlp_daemon_collector" {
  depends_on = [
    helm_release.kube_state_metrics,
    helm_release.prometheus_node_exporter
  ]

  yaml_body = yamlencode({
    apiVersion = "opentelemetry.io/v1beta1"
    kind       = "OpenTelemetryCollector"
    metadata = {
      name      = "grafana-otlp-daemon-collector"
      namespace = kubernetes_namespace.grafana.metadata[0].name
    }
    spec = {
      mode           = "daemonset"
      serviceAccount = kubernetes_service_account.grafana_otlp_collector.metadata[0].name
      tolerations = concat(
        local.tolerations_from_node_selector,
        [
          {
            key      = "CriticalAddonsOnly"
            operator = "Exists"
            effect   = "NoSchedule"
          }
        ]
      )
      volumes = [
        {
          name = "varlog"
          hostPath = {
            path = "/var/log"
            type = "Directory"
          }
        }
      ]
      volumeMounts = [
        {
          name      = "varlog"
          mountPath = "/var/log"
          readOnly  = true
        }
      ]
      env = [
        {
          name = "GRAFANA_CLOUD_PASSWORD"
          valueFrom = {
            secretKeyRef = {
              name = kubernetes_secret.grafana_cloud_config.metadata[0].name
              key  = "password"
            }
          }
        }
      ]
      resources = {
        requests = {
          cpu    = "50m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
      config = {
        extensions = {
          "basicauth/loki" = {
            client_auth = {
              username = var.grafana_loki_username
              password = "$${GRAFANA_CLOUD_PASSWORD}"
            }
          }
        }

        receivers = {
          filelog = {
            include = [
              "/var/log/pods/*/*/*.log"
            ]
            start_at          = "end"
            include_file_path = true
            include_file_name = false
            operators = [
              # Find out which format is used by kubernetes
              {
                type = "router"
                id   = "get-format"
                routes = [
                  {
                    output = "parser-docker"
                    expr   = "body matches \"^\\\\{\""
                  },
                  {
                    output = "parser-crio"
                    expr   = "body matches \"^[^ Z]+ \""
                  },
                  {
                    output = "parser-containerd"
                    expr   = "body matches \"^[^ Z]+Z\""
                  }
                ]
              },
              # Parse CRI-O format
              {
                type   = "regex_parser"
                id     = "parser-crio"
                regex  = "^(?P<time>[^ Z]+) (?P<stream>stdout|stderr) (?P<logtag>[^ ]*) ?(?P<log>.*)$"
                output = "extract_metadata_from_filepath"
                timestamp = {
                  parse_from  = "attributes.time"
                  layout_type = "gotime"
                  layout      = "2006-01-02T15:04:05.999999999Z07:00"
                }
              },
              # Parse CRI-Containerd format
              {
                type   = "regex_parser"
                id     = "parser-containerd"
                regex  = "^(?P<time>[^ ^Z]+Z) (?P<stream>stdout|stderr) (?P<logtag>[^ ]*) ?(?P<log>.*)$"
                output = "extract_metadata_from_filepath"
                timestamp = {
                  parse_from = "attributes.time"
                  layout     = "%Y-%m-%dT%H:%M:%S.%LZ"
                }
              },
              # Parse Docker format
              {
                type   = "json_parser"
                id     = "parser-docker"
                output = "extract_metadata_from_filepath"
                timestamp = {
                  parse_from = "attributes.time"
                  layout     = "%Y-%m-%dT%H:%M:%S.%LZ"
                }
              },
              {
                type = "move"
                from = "attributes.log"
                to   = "body"
              },
              # Extract metadata from file path
              {
                type       = "regex_parser"
                id         = "extract_metadata_from_filepath"
                regex      = "^.*\\/(?P<namespace>[^_]+)_(?P<pod_name>[^_]+)_(?P<uid>[a-f0-9\\-]{16,36})\\/(?P<container_name>[^\\._]+)\\/(?P<restart_count>\\d+)\\.log$"
                parse_from = "attributes[\"log.file.path\"]"
                cache = {
                  size = 128
                }
              },
              # Rename attributes
              {
                type = "move"
                from = "attributes[\"log.file.path\"]"
                to   = "resource[\"filename\"]"
              },
              {
                type = "move"
                from = "attributes.container_name"
                to   = "resource[\"container\"]"
              },
              {
                type = "move"
                from = "attributes.namespace"
                to   = "resource[\"namespace\"]"
              },
              {
                type = "move"
                from = "attributes.pod_name"
                to   = "resource[\"pod\"]"
              },
              {
                type  = "add"
                field = "resource[\"cluster\"]"
                value = var.grafana_cluster_name
              }
            ]
          }
        }

        processors = {
          resource = {
            attributes = [
              {
                action = "insert"
                key    = "loki.format"
                value  = "raw"
              },
              {
                action = "insert"
                key    = "loki.resource.labels"
                value  = "pod, namespace, container, cluster, filename"
              }
            ]
          }
        }

        exporters = {
          "loki/grafana" = {
            endpoint = var.grafana_loki_push_url
            auth = {
              authenticator = "basicauth/loki"
            }
          }
        }

        service = {
          extensions = [
            "basicauth/loki"
          ]
          pipelines = {
            logs = {
              receivers  = ["filelog"]
              processors = ["resource"]
              exporters  = ["loki/grafana"]
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
    "status"
  ]
}
