# Pi-hole Log Forwarding with Promtail

This repository holds the configuration and scripts used inside the `pihole` LXC container (ID: 110) on your Proxmox server. It is responsible for:

- Running Pi-hole (`pihole.home`) for network-wide ad blocking
- Shipping Pi-hole logs to Grafana Loki using Promtail
- Managing renewal and reloading of TLS certificates via helper scripts

---

## 🗂️ Directory Structure

```
/
├── renew-certs/
│   └── renew.sh
├── services.config.yaml
└── etc/
    └── promtail/
        ├── promtail.yaml
        └── promtail.yaml.bak
```

---

## 🔧 Configuration

### `services.config.yaml`

This file lists all services whose certificates are managed by your internal `step-ca` authority. It allows you to define:

- Hostname (used for certificate CN/SAN)
- Certificate paths
- Optional reload commands after renewal

Example structure:

```yaml
services:
  - name: pihole
    hostname: pihole.home
    cert_path: /etc/ssl/certs/pihole.pem
    key_path: /etc/ssl/private/pihole.key
    reload_cmd: "service lighttpd restart"
```

This config is read by the `renew.sh` script to automate cert renewal and reloading.

---

### `etc/promtail/promtail.yaml`

This is the main config file for Promtail. It defines:

- Log sources (`/var/log/pihole/*.log`)
- Labels (e.g., job and host)
- The Loki endpoint to push logs to

Example structure:

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /var/log/positions-pihole.yaml

clients:
  - url: http://10.0.0.61:3100/loki/api/v1/push

scrape_configs:
  - job_name: pihole
    static_configs:
      - targets:
          - localhost
        labels:
          job: pihole
          host: pihole.home
          __path__: /var/log/pihole/*.log
```

> **Note**: Replace the Loki URL if your host IP changes.

---

## 📜 Scripts

### `renew-certs/renew.sh`

Bash script that:

- Iterates over entries in `services.config.yaml`
- Requests a new certificate from `step-ca` for each service
- Places the cert and key in the correct paths
- Runs the service’s `reload_cmd` if defined

You can schedule this script with `cron` or run it manually:

```bash
~/renew-certs/renew.sh
```

Make sure it's executable:

```bash
chmod +x ~/renew-certs/renew.sh
```

---

## 🚀 Promtail Setup & Usage

Promtail is installed in `/opt/promtail`. It's responsible for tailing Pi-hole logs and pushing them to Loki.

Install steps (if needed):

```bash
mkdir -p /opt/promtail
cd /opt/promtail
wget https://github.com/grafana/loki/releases/latest/download/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip
chmod +x promtail-linux-amd64
mv promtail-linux-amd64 promtail
```

You can start Promtail manually with:

```bash
/opt/promtail/promtail -config.file /etc/promtail/promtail.yaml
```

Or set it up as a service (see your service unit or container supervisor).

---

## 🛠️ Troubleshooting

### File exists but won't open

If you see:
```bash
cat: promtail.yaml: No such file or directory
```
Even though `ls` shows the file, check for hidden characters:

```bash
ls -lb /etc/promtail
```

If you see `promtail.yaml\r`, rename with:

```bash
mv "$(ls | grep promtail.yaml)" promtail.yaml
```

### Validate config

To verify Promtail config is valid:

```bash
/opt/promtail/promtail -config.file /etc/promtail/promtail.yaml -validate-config
```

---

## 🔐 Security Notes

- Certificates are issued by your internal `step-ca` CA running in your `docker-machine` VM.
- Cert renewal should be done via script, and root cert is served from an internal web server at `http://stepca.home:8080/root_ca.crt`.

---

## 📅 Recommendations

- Schedule `renew.sh` via cron or systemd to keep certs fresh
- Regularly monitor Promtail logs and `/var/log/pihole/*.log` for ingestion errors
- Adjust Promtail labels to include additional context (e.g., container, service name)

---

## 📍 System Overview

This container is part of your Proxmox-based home server setup:

- **Pi-hole Container (ID 110)**: Hosts this repo, forwards logs, blocks ads
- **Docker VM (ID 100)**: Hosts Loki, Grafana, Nginx Proxy Manager, step-ca
- **Grafana**: Used to visualize logs from Pi-hole and other services
