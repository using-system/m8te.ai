resource "grafana_rule_group" "tempo" {
  name             = "tempo"
  folder_uid       = grafana_folder.k8s.uid
  interval_seconds = 1800


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
}
