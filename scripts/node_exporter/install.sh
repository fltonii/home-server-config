#!/bin/bash
set -e

# === Input check ===
SERVICE_NAME="$1"
if [[ -z "$SERVICE_NAME" ]]; then
  echo "Usage: $0 <service_name>"
  exit 1
fi

# === Paths ===
REPO_ROOT="$(dirname "$(realpath "$0")")/../.."
TEMPLATE="$REPO_ROOT/templates/node_exporter.service.template"
SERVICE_DIR="$REPO_ROOT/$SERVICE_NAME"
SERVICE_DEST="$SERVICE_DIR/node_exporter.service"
SYSTEMD_TARGET="/etc/systemd/system/node_exporter.service"
NODE_EXPORTER_BIN="/usr/local/bin/node_exporter"

# === Install node_exporter if needed ===
if ! command -v node_exporter &>/dev/null; then
  echo "⬇️  Installing node_exporter..."
  cd /tmp
  wget -q https://github.com/prometheus/node_exporter/releases/latest/download/node_exporter-1.8.1.linux-amd64.tar.gz
  tar -xzf node_exporter-*.tar.gz
  sudo mv node_exporter-*/node_exporter "$NODE_EXPORTER_BIN"
  sudo chmod +x "$NODE_EXPORTER_BIN"
  rm -rf node_exporter*
  echo "✅ Installed node_exporter at $NODE_EXPORTER_BIN"
else
  echo "✅ node_exporter already installed at $NODE_EXPORTER_BIN"
fi

# === Generate systemd service file ===
echo "🛠 Generating $SERVICE_DEST..."
mkdir -p "$SERVICE_DIR"

sed \
  -e "s|__BINARY_PATH__|$NODE_EXPORTER_BIN|g" \
  "$TEMPLATE" > "$SERVICE_DEST"

# === Symlink to systemd location ===
echo "🔗 Linking to systemd: $SYSTEMD_TARGET"
sudo ln -sf "$SERVICE_DEST" "$SYSTEMD_TARGET"

# === Enable and start the service ===
echo "🚀 Enabling and starting node_exporter..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter

# === Confirm ===
echo "✅ node_exporter status:"
sudo systemctl status node_exporter --no-pager
