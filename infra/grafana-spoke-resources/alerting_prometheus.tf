resource "grafana_rule_group" "prometheus" {
  name             = "prometheus"
  folder_uid       = grafana_folder.k8s.uid
  interval_seconds = 300

  rule {
    name      = "PrometheusSelfScrapeDown"
    condition = "Condition"
    for       = "5m"

    data {
      ref_id = "Up"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "up{job=\"prometheus\"}"
      })
    }

    data {
      ref_id = "ReduceUp"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        expression = "Up"
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
        expression = "$ReduceUp == 0"
      })
    }

    annotations = {
      summary     = "Prometheus server is down"
      description = "The Prometheus server (job=\"prometheus\") has returned up == 0 for the last 5 minutes."
    }

    labels = {
      severity = "critical"
    }

    notification_settings {
      contact_point = "default"
      group_by      = []
      mute_timings  = []
    }
  }

  rule {
    name      = "PrometheusHighHeapAlloc"
    condition = "Condition"
    for       = "0s"

    data {
      ref_id = "HeapAlloc"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "go_memstats_heap_alloc_bytes{job=\"prometheus\"}"
      })
    }

    data {
      ref_id = "ReduceHeap"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        expression = "HeapAlloc"
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
        expression = "$ReduceHeap > 5e9"
      })
    }

    annotations = {
      summary     = "High Go heap allocation in Prometheus"
      description = "go_memstats_heap_alloc_bytes > 1 GiB for job=« prometheus »."
    }

    labels = {
      severity = "warning"
    }

    notification_settings {
      contact_point = "default"
      group_by      = []
      mute_timings  = []
    }
  }

  rule {
    name      = "PrometheusHighCPU"
    condition = "Condition"
    for       = "0s"

    data {
      ref_id = "CPURate"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "rate(process_cpu_seconds_total{job=\"prometheus\"}[5m])"
      })
    }

    data {
      ref_id = "ReduceCPU"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        expression = "CPURate"
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
        expression = "$ReduceCPU > 0.5"
      })
    }

    annotations = {
      summary     = "High CPU usage by Prometheus process"
      description = "The Prometheus process is averaging more than 50% of a CPU core (0.5 CPU-s/s) over the last 5 minutes."
    }

    labels = {
      severity = "warning"
    }

    notification_settings {
      contact_point = "default"
      group_by      = []
      mute_timings  = []
    }
  }
}
