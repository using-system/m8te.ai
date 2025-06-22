# m8te.ai

```bash
cd m8te.ai
```

## What is it?

```bash
cat description.txt
```

**M8te.ai** is a cutting-edge, secure chatbot solution that lets you query any type of data—whether it's databases, text files, or other sources—using natural language. It offers a flexible, model-selecting interface while ensuring your sensitive data stays on-site through localized, agent-based processing. Embrace your smart data companion with M8te.ai!


## Components

```bash
cat components.diagram
```

```mermaid
flowchart TD
    user((User))
    landingapp["Landing App (next.js)"]
    dashboardapp["Dashboard App (next.js)"]
    gateway["Gateway API (.net9/ocelot)"]
    accountms["Account Management MS (.net9/aot)"]
    connect["Connect (keycloak)"]
    connectpsql[PostgreSQL]

    user -->|browse| landingapp
    user -->|browse| dashboardapp
    user -->|rest| gateway
    user -->|oidc| connect
    dashboardapp -->|rest| gateway
    dashboardapp -->|oidc| connect
    gateway -->|rest| accountms
    gateway -->|oidc| connect
    accountms -->|rest| connect
    connect -->|psql| connectpsql
```

## Observability

```bash
cat observability.diagram
```

```mermaid
flowchart TD
    user((User))
    grafana[Grafana]
    component[Components]
    otlp[OpenTelemetry Collector]
    consumer[Observability Stack]
    prometheus[Prometheus / Thanos]
    loki[Loki]
    tempo[Tempo]
    pyroscope[Pyroscope]

    user -->|browse| grafana
    component -->|gRPC| otlp
    grafana -->|gRPC| consumer
    otlp -->|gRPC| consumer
    consumer -->|gRPC/metrics| prometheus
    consumer -->|gRPC/logs| loki
    consumer -->|gRPC/trace| tempo
    consumer -->|gRPC/profiler| pyroscope
```