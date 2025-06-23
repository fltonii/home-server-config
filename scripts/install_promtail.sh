#!/bin/bash
set -e

SERVICE_NAME="$1"

if [[ -z "$SERVICE_NAME" ]]; then
  echo "Usage: $0 <service_name> (must contain service.config.yaml and generated promtail.* files)"
  exit 1
fi

REPO_ROOT="$(dirname "$(realpath "$0")")/.."
SERVICE_DIR="$REPO_ROOT/$SERVICE_NAME"
CONFIG_YAML="$SERVICE_DIR/service.config.yaml"
PROMTAIL_CONFIG="$SERVICE_DIR/promtail.yaml"
PROMTAIL_SERVICE="$SERVICE_DIR/promtail.service"

CONFIG_TARGET="/etc/promtail/promtail.yaml"
SERVICE_TARGET="/etc/systemd/system/promtail.service"
BINARY_PATH="/opt/promtail"
PROMTAIL_VERSION="2.9.4"

# === Check dependencies ===
if ! command -v yq &>/dev/null; then
  echo "❌ 'yq' is required. Install with: sudo apt install yq"
  exit 1
fi

# === Check files ===
if [[ ! -f "$CONFIG_YAML" || ! -f "$PROMTAIL_CONFIG" || ! -f "$PROMTAIL_SERVICE" ]]; then
  echo "❌ Missing required files in $SERVICE_DIR"
  exit 1
fi

PROMTAIL_ENABLED=$(yq -r '.promtail.enabled' "$CONFIG_YAML")
if [[ "$PROMTAIL_ENABLED" != "true" ]]; then
  echo "ℹ️  Promtail not enabled in $CONFIG_YAML. Skipping install."
  exit 0
fi

echo "📦 Installing Promtail for $SERVICE_NAME"

# === Step 1: Install Promtail binary ===
if [[ ! -f "$BINARY_PATH" ]]; then
  echo "⬇️  Downloading Promtail $PROMTAIL_VERSION..."
  cd /tmp
  wget -q "https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip" -O promtail.zip
  unzip -o promtail.zip
  rm promtail.zip
  sudo mv promtail-linux-amd64 "$BINARY_PATH"
  sudo chmod +x "$BINARY_PATH"
  echo "✅ Promtail installed at $BINARY_PATH"
else
  echo "✅ Promtail already installed at $BINARY_PATH"
fi

# === Step 2: Symlink config ===
echo "🔗 Symlinking Promtail config..."
sudo mkdir -p /etc/promtail
sudo ln -sf "$PROMTAIL_CONFIG" "$CONFIG_TARGET"

# === Step 3: Symlink service file ===
echo "🔗 Symlinking systemd service..."
sudo ln -sf "$PROMTAIL_SERVICE" "$SERVICE_TARGET"

# === Step 4: Reload and start service ===
echo "🚀 Starting promtail.service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now promtail

# === Step 5: Verify ===
sudo systemctl status promtail --no-pager
