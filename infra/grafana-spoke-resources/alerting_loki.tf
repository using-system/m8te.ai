resource "grafana_rule_group" "loki" {
  name             = "loki"
  folder_uid       = grafana_folder.k8s.uid
  interval_seconds = 1800

  rule {
    name      = "LokiCanaryMissingEntries"
    condition = "Condition"
    for       = "0s"

    data {
      ref_id = "MissingEntries"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "sum(increase(loki_canary_missing_entries_total[5m])) by (instance)"
      })
    }

    data {
      ref_id = "ReduceMissingEntries"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        expression = "MissingEntries"
        type       = "reduce"
        reducer    = "last"
      })
    }

    data {
      ref_id = "Condition"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        type       = "math"
        expression = "$ReduceMissingEntries > 0"
      })
    }

    annotations = {
      summary     = "Loki canary detected missing log entries on instance {{ $labels.instance }}"
      description = "The Loki Canary for instance {{ $labels.instance }} has reported missing entries in the last 5 minutes, indicating potential issues with ingestion or query."
    }

    labels = {
      severity = "critical"
    }

    notification_settings {
      contact_point = "default"
      group_by      = ["instance"]
      mute_timings  = []
    }
  }

  rule {
    name      = "LokiHighQueryLatency"
    condition = "Condition"
    for       = "0s"

    data {
      ref_id = "P99Latency"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "histogram_quantile(0.99, sum(rate(loki_request_duration_seconds_bucket[5m])) by (le, job))"
      })
    }

    data {
      ref_id = "ReduceP99"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        expression = "P99Latency"
        type       = "reduce"
        reducer    = "last"
      })
    }

    data {
      ref_id = "Condition"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        type       = "math"
        expression = "$ReduceP99 > 1"
      })
    }

    annotations = {
      summary     = "High query latency (>1s) on {{ $labels.job }}"
      description = "The 99th percentile of request latency for job {{ $labels.job }} has exceeded 1 second over the last 5 minutes."
    }

    labels = {
      severity = "critical"
    }

    notification_settings {
      contact_point = "default"
      group_by      = ["job"]
      mute_timings  = []
    }
  }

  rule {
    name      = "LokiIngesterMemoryHigh"
    condition = "Condition"
    for       = "0s"

    data {
      ref_id = "MemoryBytes"
      relative_time_range {
        from = 300 # last 5m
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "sum(container_memory_working_set_bytes{namespace=\"loki\",pod=~\"loki-ingester-.*\"}) by (pod)"
      })
    }

    data {
      ref_id = "ReduceMemory"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        expression = "MemoryBytes"
        type       = "reduce"
        reducer    = "last"
      })
    }

    #Fire if any ingester pod is over 4 GiB
    data {
      ref_id = "Condition"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        type       = "math"
        expression = "$ReduceMemory > 4e9"
      })
    }

    annotations = {
      summary     = "High memory usage on ingester pod {{ $labels.pod }}"
      description = "In the last 5 minutes, ingester pod {{ $labels.pod }} has a working-set memory > 4 GiB, which may indicate excessive chunk buildup or memory leak."
    }

    labels = {
      severity = "warning"
    }

    notification_settings {
      contact_point = "default"
      group_by      = ["pod"]
      mute_timings  = []
    }
  }

  rule {
    name      = "LokiHighErrorLogVolume"
    condition = "Condition"
    for       = "0s"

    data {
      ref_id = "ErrorLogCount"
      relative_time_range {
        from = 3600
        to   = 0
      }
      datasource_uid = data.grafana_data_source.loki.uid
      model = jsonencode({
        expr = "sum(count_over_time({app=~\".+\",namespace=~\".+\"} |= \"level=error\" [1h])) by (app, namespace)"
      })
    }

    data {
      ref_id = "ReduceErrorLogCount"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        expression = "ErrorLogCount"
        type       = "reduce"
        reducer    = "last"
      })
    }

    data {
      ref_id = "Condition"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        type       = "math"
        expression = "$ReduceErrorLogCount > 250"
      })
    }

    annotations = {
      summary     = "High ERROR log volume for {{ $labels.app }} in {{ $labels.namespace }}"
      description = "More than 250 ERROR-level log entries were generated in the last hour by application {{ $labels.app }} in namespace {{ $labels.namespace }}."
    }

    labels = {
      severity = "critical"
    }

    notification_settings {
      contact_point = "default"
      group_by      = ["app", "namespace"]
      mute_timings  = []
    }
  }


}
