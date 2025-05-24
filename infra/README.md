# m8te.ai Infrastructure

To run in this order : 

 - az-hub-network : Global network, acr, firewall..
 - az-spoke-network : Network per infrastructure environment
 - az-spoke-resources : Azure resources for the spoke environment
 - k8s-core-resources : K8s Core resources (api gateway, otlp operator, certmanager...)
 - k8s-istio : K8s istio system
 - k8s-devops : K8s devops resources (github runners)
 - k8s-obs : Observability layer (Grafana, Prometheus, tempo, lolki, pyroscope...)
 - k8s-spoke-resources : K8s resources for the spoke environement (MongoDB...)
 - grafana-spoke-resources : Grafana resources for the spoke environment (Datasources, Dashboards, Alerting...)
 - app-spoke-resources : K8s/azure resources for co.bike applications (micro services, frontend...)