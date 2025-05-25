resource "grafana_rule_group" "thanos" {
  name             = "thanos"
  folder_uid       = grafana_folder.k8s.uid
  interval_seconds = 1800


  rule {
    name      = "ThanosStoreBlockLoadHighLatency"
    condition = "Condition"
    for       = "0s"

    data {
      ref_id = "P99Load"
      relative_time_range {
        from = 300 # last 5m
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "histogram_quantile(0.99, sum(rate(thanos_bucket_store_block_load_duration_seconds_bucket[5m])) by (le, instance))"
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
        expression = "P99Load"
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
        expression = "$ReduceP99 > 5"
      })
    }

    annotations = {
      summary     = "High block-load latency (>5s) on Thanos Store instance {{ $labels.instance }}"
      description = "The 99th percentile of block-load duration for Thanos Store (instance {{ $labels.instance }}) has exceeded 5 seconds over the last 5 minutes."
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

  rule {
    name      = "ThanosObjstoreBucketOpFailures"
    condition = "Condition"
    for       = "0s"

    data {
      ref_id = "Failures"
      relative_time_range {
        from = 300 # last 5m
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "sum(increase(thanos_objstore_bucket_operation_failures_total[5m])) by (instance, operation)"
      })
    }

    data {
      ref_id = "ReduceFailures"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        expression = "Failures"
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
        expression = "$ReduceFailures > 0"
      })
    }

    annotations = {
      summary     = "Object store bucket operation failures on Thanos instance {{ $labels.instance }}"
      description = "There have been {{ $value }} bucket operation failures (operation={{ $labels.operation }}) on instance {{ $labels.instance }} in the last 5 minutes."
    }

    labels = {
      severity = "critical"
    }

    notification_settings {
      contact_point = "default"
      group_by      = ["instance", "operation"]
      mute_timings  = []
    }
  }


  rule {
    name      = "ThanosQueryEndpointDNSFailures"
    condition = "Condition"
    for       = "0s"

    data {
      ref_id = "DNSFails"
      relative_time_range {
        from = 300 # last 5 minutes
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "sum(increase(thanos_query_endpoints_dns_failures_total[5m])) by (instance, endpoint)"
      })
    }

    data {
      ref_id = "ReduceDNSFails"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        expression = "DNSFails"
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
        expression = "$ReduceDNSFails > 0"
      })
    }

    annotations = {
      summary     = "DNS resolution failures for endpoint {{ $labels.endpoint }} on Thanos Query instance {{ $labels.instance }}"
      description = "Thanos Query (instance {{ $labels.instance }}) has encountered {{ $value }} DNS resolution failures for endpoint '{{ $labels.endpoint }}' in the last 5 minutes."
    }

    labels = {
      severity = "warning"
    }

    notification_settings {
      contact_point = "default"
      group_by      = ["instance", "endpoint"]
      mute_timings  = []
    }
  }

  rule {
    name      = "ThanosStoreAPIHighLatency"
    condition = "Condition"
    for       = "0s"

    data {
      ref_id = "P99StoreAPI"
      relative_time_range {
        from = 300 # last 5 minutes
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr = "histogram_quantile(0.99, sum(rate(thanos_store_api_query_duration_seconds_bucket[5m])) by (le, instance))"
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
        expression = "P99StoreAPI"
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
        expression = "$ReduceP99 > 0.5"
      })
    }

    annotations = {
      summary     = "High store-API query latency (>500 ms) on Thanos Store Gateway instance {{ $labels.instance }}"
      description = "The 99th percentile of store-API query duration on instance {{ $labels.instance }} has exceeded 0.5 s over the last 5 minutes, which may indicate I/O or network bottlenecks."
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
