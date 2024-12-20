# Infrastructure co.bike

To run in this order : 

 - az-hub-network : Global network, acr, firewall..
 - az-spoke-network : Network per infrastructure environment
 - az-spoke-resources : Azure resource for the spoke environment
 - k8s-spoke-resources : Kubernetes resources for the spoke environement (Grafana, Prometheus, KubeCost, OTel Collector, MongoDB...)
 - grafana-spoke-resources : Grafana resource for the spoke environment (Datasources, Dashboard, alerting...)
 - app-spoke-resources : Co.Bike Applications (micro services, frontend...)