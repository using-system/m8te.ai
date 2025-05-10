resource "grafana_rule_group" "kube_state_metrics" {
  name             = "kube-state-metrics"
  folder_uid       = grafana_folder.k8s.uid
  interval_seconds = 300

  rule {
    name      = "NodeNotReady"
    condition = "Condition"

    data {
      ref_id = "NodeNotReady"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "kube_node_status_condition{condition=\"Ready\",status=\"false\"}"
      })
    }

    data {
      ref_id = "ReduceNodeNotReady"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model          = jsonencode({ expression = "NodeNotReady", type = "reduce", reducer = "last" })
    }

    data {
      ref_id = "Condition"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model          = jsonencode({ type = "math", expression = "$ReduceNodeNotReady > 0" })
    }

    annotations = {
      summary     = "Kubernetes Node {{ $labels.node }} Not Ready"
      description = "Node {{ $labels.node }} is in NotReady state."
    }

    labels = {
      severity = "critical"
    }

    notification_settings {
      contact_point = "default"
      group_by      = null
      mute_timings  = []
    }
  }

  rule {
    name      = "K8sHighCPUUsage"
    condition = "Condition"

    data {
      ref_id = "CpuUsage"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "sum(rate(container_cpu_usage_seconds_total{namespace!=\"\", namespace!=\"kube-system\"}[5m])) by (namespace, pod)"
      })
    }

    data {
      ref_id = "ReduceCpuUsage"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model          = jsonencode({ expression = "CpuUsage", type = "reduce", reducer = "last" })
    }

    data {
      ref_id = "Condition"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model          = jsonencode({ type = "math", expression = "$ReduceCpuUsage > 0.9" })
    }

    annotations = {
      summary     = "High CPU usage detected on {{ $labels.pod }}"
      description = "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} has exceeded 90% CPU usage."
    }

    labels = {
      severity = "warning"
    }

    notification_settings {
      contact_point = "default"
      group_by      = null
      mute_timings  = []
    }
  }

  rule {
    name      = "K8sHighMemoryUsage"
    condition = "Condition"

    data {
      ref_id = "MemoryUsageRatio"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "sum(container_memory_usage_bytes{namespace!=\"\", namespace!=\"kube-system\"}) by (namespace, pod) / sum(container_spec_memory_limit_bytes{namespace!=\"\", namespace!=\"kube-system\"}) by (namespace, pod)"
      })
    }

    data {
      ref_id = "ReduceMemoryUsageRatio"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model          = jsonencode({ expression = "MemoryUsageRatio", type = "reduce", reducer = "last" })
    }

    data {
      ref_id = "Condition"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model          = jsonencode({ type = "math", expression = "($ReduceMemoryUsageRatio > 0.9) && !is_inf($ReduceMemoryUsageRatio)" })
    }

    annotations = {
      summary     = "High memory usage detected on {{ $labels.pod }}"
      description = "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} has exceeded 90% memory usage."
    }

    labels = {
      severity = "warning"
    }

    notification_settings {
      contact_point = "default"
      group_by      = null
      mute_timings  = []
    }
  }

  rule {
    name      = "K8sPodCrashLooping"
    condition = "Condition"

    data {
      ref_id = "PodRestarts"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "rate(kube_pod_container_status_restarts_total[5m])"
      })
    }

    data {
      ref_id = "ReducePodRestarts"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model          = jsonencode({ expression = "PodRestarts", type = "reduce", reducer = "last" })
    }

    data {
      ref_id = "Condition"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model          = jsonencode({ type = "math", expression = "$ReducePodRestarts > 0.1" })
    }

    annotations = {
      summary     = "CrashLoop detected on pod {{ $labels.pod }}"
      description = "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} has been continuously restarting for more than 5 minutes."
    }

    labels = {
      severity = "critical"
    }

    notification_settings {
      contact_point = "default"
      group_by      = null
      mute_timings  = []
    }
  }

  rule {
    name      = "K8sDeploymentReplicasMismatch"
    condition = "Condition"

    data {
      ref_id = "DeployAvailable"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "sum by(deployment, namespace)(kube_deployment_status_replicas_available{namespace!=\"\", namespace!=\"kube-system\"})"
      })
    }

    data {
      ref_id = "ReduceDeployAvailable"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model          = jsonencode({ expression = "DeployAvailable", type = "reduce", reducer = "last" })
    }

    data {
      ref_id = "DeployDesired"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "sum by(deployment, namespace)(kube_deployment_spec_replicas{namespace!=\"\", namespace!=\"kube-system\"})"
      })
    }

    data {
      ref_id = "ReduceDeployDesired"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model          = jsonencode({ expression = "DeployDesired", type = "reduce", reducer = "last" })
    }

    data {
      ref_id = "Condition"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model          = jsonencode({ type = "math", expression = "$ReduceDeployAvailable != $ReduceDeployDesired" })
    }

    annotations = {
      summary     = "Replica count mismatch for deployment {{ $labels.deployment }}"
      description = "Deployment {{ $labels.deployment }} in namespace {{ $labels.namespace }} has not had the expected number of available replicas for more than 10 minutes."
    }

    labels = {
      severity = "warning"
    }

    notification_settings {
      contact_point = "default"
      group_by      = null
      mute_timings  = []
    }
  }

  rule {
    name      = "K8sPersistentVolumeFull"
    condition = "Condition"

    data {
      ref_id = "BytesAvailableRatio"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "kubelet_volume_stats_available_bytes / kubelet_volume_stats_capacity_bytes"
      })
    }

    data {
      ref_id = "ReduceBytesAvailableRatio"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model          = jsonencode({ expression = "BytesAvailableRatio", type = "reduce", reducer = "last" })
    }

    data {
      ref_id = "Condition"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model          = jsonencode({ type = "math", expression = "$ReduceBytesAvailableRatio < 0.1" })
    }

    annotations = {
      summary     = "Persistent volume on {{ $labels.persistentvolumeclaim }} is almost full"
      description = "Remaining free space on persistent volume {{ $labels.persistentvolumeclaim }} in namespace {{ $labels.namespace }} is below 10%."
    }

    labels = {
      severity = "critical"
    }

    notification_settings {
      contact_point = "default"
      group_by      = null
      mute_timings  = []
    }
  }

}
