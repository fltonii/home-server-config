#!/bin/bash
set -e

# === Defaults ===
PROMTAIL_VERSION="2.9.4"
INSTALL_DIR="/opt/promtail"
CONFIG_TEMPLATE="/root/home-server-config/promtail/promtail.template.yaml"

# === Args / Env vars ===
NAME="${NAME:-$1}"                        # e.g. pihole
HOST="${HOST:-$2}"                        # e.g. pihole.home
LOG_PATH="${LOG_PATH:-$3}"               # e.g. /var/log/pihole/*.log
LOKI_URL="${LOKI_URL:-$4}"               # e.g. 10.0.0.61

# === Derived paths ===
SERVICE_NAME="promtail"
BIN_PATH="$INSTALL_DIR/promtail"
CONFIG_TARGET="/etc/promtail/promtail.yaml"
SERVICE_SOURCE="/root/home-server-config/promtail/promtail.service"
SERVICE_TARGET="/etc/systemd/system/${SERVICE_NAME}.service"

# === Validate inputs ===
if [[ -z "$NAME" || -z "$HOST" || -z "$LOG_PATH" || -z "$LOKI_URL" ]]; then
  echo "Usage: NAME=xxx HOST=xxx LOG_PATH=xxx LOKI_URL=xxx ./install_promtail.sh"
  echo "Or:    ./install_promtail.sh <name> <host> <log_path> <loki_url>"
  exit 1
fi

echo "📦 Installing Promtail $PROMTAIL_VERSION for $NAME ($HOST)..."

# === Download and install Promtail binary ===
echo "⬇️  Downloading Promtail..."
cd /tmp
wget -q "https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip" -O promtail.zip
unzip -o promtail.zip
rm promtail.zip
sudo mv /tmp/promtail-linux-amd64 "$INSTALL_DIR"
sudo chmod +x "$INSTALL_DIR"
echo "✅ Promtail binary installed at $INSTALL_DIR"

# === Step 2: Generate config from template ===
echo "⚙️ Generating Promtail config..."
sudo mkdir -p /etc/promtail
sed \
  -e "s|__NAME__|$NAME|g" \
  -e "s|__HOST__|$HOST|g" \
  -e "s|__LOG_PATH__|$LOG_PATH|g" \
  -e "s|__LOKI_URL__|$LOKI_URL|g" \
  "$CONFIG_TEMPLATE" | sudo tee "$CONFIG_TARGET" > /dev/null

# === Step 3: Link service file ===
echo "🔗 Linking systemd service..."
sudo ln -sf "$SERVICE_SOURCE" "$SERVICE_TARGET"

# === Step 4: Start Promtail ===
echo "🚀 Starting $SERVICE_NAME..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now "$SERVICE_NAME"

# === Step 5: Confirm ===
sudo systemctl status "$SERVICE_NAME" --no-pager
