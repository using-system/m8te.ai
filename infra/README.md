# Infrastructure co.bike

To run in this order : 

 - az-hub-network : Global network, acr, firewall..
 - az-spoke-network : Network per infrastructure environment
 - az-spoke-resources : Azure resources for the spoke environment
 - k8s-gtw-api : K8s Gateway api
 - k8s-istio : K8s istio system
 - k8s-spoke-resources : K8s resources for the spoke environement (Grafana, Prometheus, KubeCost, OTel Collector, MongoDB...)
 - grafana-spoke-resources : Grafana resources for the spoke environment (Datasources, Dashboards, Alerting...)
 - app-spoke-resources : K8s/azure resources for co.bike applications (micro services, frontend...)