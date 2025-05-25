resource "grafana_rule_group" "tempo" {
  name             = "tempo"
  folder_uid       = grafana_folder.k8s.uid
  interval_seconds = 1800


  rule {
    name      = "TempoHighQueryLatency"
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
        expr = "histogram_quantile(0.99, sum by (le, job) (rate(tempo_request_duration_seconds_bucket[5m])))"
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
      summary     = "High P99 latency (>1 s) on {{ $labels.job }}"
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
    name      = "TempoIngesterHighMemory"
    condition = "Condition"
    for       = "0s"

    data {
      ref_id = "MemoryUsage"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "sum(container_memory_working_set_bytes{namespace=\"tempo\", pod=~\"tempo-ingester-.*\"}) by (pod)"
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
        expression = "MemoryUsage"
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
        expression = "$ReduceMemory > 4e9"
      })
    }

    annotations = {
      summary     = "High memory usage on Tempo ingester"
      description = "In the last 5 minutes, Tempo ingester pod {{ $labels.pod }} has used > 4 GiB of working-set memory."
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
    name      = "TempoIngesterFlushFailures"
    condition = "Condition"
    for       = "5m"

    data {
      ref_id = "FlushFailures"
      relative_time_range {
        from = 3600
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "sum(increase(tempo_ingester_failed_flushes_total[1h])) by (instance)"
      })
    }

    data {
      ref_id = "ReduceFlushFailures"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        expression = "FlushFailures"
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
        expression = "$ReduceFlushFailures > 0"
      })
    }

    annotations = {
      summary     = "Tempo ingester flush failures detected"
      description = "There were flush failures in one or more Tempo ingesters within the last hour."
    }

    labels = {
      severity = "warning"
    }

    notification_settings {
      contact_point = "default"
      group_by      = ["instance"]
      mute_timings  = []
    }
  }
}
