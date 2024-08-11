# Grafana-Prometheus

Monitoring system resource using Grafana, Prometheus, Node exporter & Alert manager.

## Feature

- Alert manager integrated with Discord
- Dashboard is available automatically

## Run

```bash
git clone https://github.com/danielcristho/docker-stuff.git && cd docker-stuff
```

```bash
cd single-node/grafana-prometheus
```

```bash
docker compose up --build -d
```

Expected output:

```bash
docker ps
CONTAINER ID   IMAGE                       COMMAND                  CREATED         STATUS         PORTS                                       NAMES
82be00054c51   prom/prometheus:v2.53.0     "/bin/prometheus --s…"   5 seconds ago   Up 3 seconds   0.0.0.0:9090->9090/tcp, :::9090->9090/tcp   prometheus
af6b6be47087   grafana/grafana:11.1.2      "/run.sh"                5 seconds ago   Up 4 seconds   0.0.0.0:3000->3000/tcp, :::3000->3000/tcp   grafana
955d7485d6b2   prom/node-exporter:v1.8.2   "/bin/node_exporter …"   5 seconds ago   Up 5 seconds   0.0.0.0:9100->9100/tcp, :::9100->9100/tcp   node-exporter
b90b6beaa911   prom/alertmanager:v0.26.0   "/bin/alertmanager -…"   5 seconds ago   Up 4 seconds   0.0.0.0:9093->9093/tcp, :::9093->9093/tcp   alert-manager
```

### Sending alert to Discord using Alert manager

