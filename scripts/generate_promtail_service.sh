#!/bin/bash
set -e

SERVICE_NAME="$1"

if [[ -z "$SERVICE_NAME" ]]; then
  echo "Usage: $0 <service_name> (must contain service.config.yaml)"
  exit 1
fi

# === Path setup ===
REPO_ROOT="$(dirname "$(realpath "$0")")/.."
SERVICE_DIR="$REPO_ROOT/$SERVICE_NAME"
CONFIG_YAML="$SERVICE_DIR/service.config.yaml"
TEMPLATE_DIR="$REPO_ROOT/templates"
TEMPLATE_CONFIG="$TEMPLATE_DIR/promtail.template.yaml"
TEMPLATE_SERVICE="$TEMPLATE_DIR/promtail.service.template"
CONFIG_OUTPUT="$SERVICE_DIR/promtail.yaml"
SERVICE_OUTPUT="$SERVICE_DIR/promtail.service"

# === Verify files ===
if [[ ! -f "$CONFIG_YAML" ]]; then
  echo "❌ Config file not found: $CONFIG_YAML"
  exit 1
fi

if [[ ! -f "$TEMPLATE_CONFIG" || ! -f "$TEMPLATE_SERVICE" ]]; then
  echo "❌ Missing template files in $TEMPLATE_DIR"
  exit 1
fi

if ! command -v yq &>/dev/null; then
  echo "❌ 'yq' is required but not installed. Install it with: sudo apt install yq"
  exit 1
fi

# === Read config values ===
PROMTAIL_ENABLED=$(yq -r '.promtail.enabled' "$CONFIG_YAML")
if [[ "$PROMTAIL_ENABLED" != "true" ]]; then
  echo "ℹ️  Promtail not enabled in $CONFIG_YAML. Skipping generation."
  exit 0
fi

NAME=$(yq -r '.service' "$CONFIG_YAML")
HOST=$(yq -r '.host' "$CONFIG_YAML")
LOG_PATH=$(yq -r '.promtail.log_path' "$CONFIG_YAML")
LOKI_URL=$(yq -r '.promtail.loki_url' "$CONFIG_YAML")

echo "📦 Generating Promtail files for $NAME..."

# === Generate promtail.yaml ===
sed \
  -e "s|__NAME__|$NAME|g" \
  -e "s|__HOST__|$HOST|g" \
  -e "s|__LOG_PATH__|$LOG_PATH|g" \
  -e "s|__LOKI_URL__|$LOKI_URL|g" \
  "$TEMPLATE_CONFIG" > "$CONFIG_OUTPUT"

# === Generate promtail.service ===
sed \
  -e "s|__SERVICE_NAME__|$NAME|g" \
  -e "s|__BINARY_PATH__|/opt/promtail|g" \
  -e "s|__CONFIG_PATH__|/etc/promtail/promtail.yaml|g" \
  "$TEMPLATE_SERVICE" > "$SERVICE_OUTPUT"

echo "✅ Generated:"
echo "  - $CONFIG_OUTPUT"
echo "  - $SERVICE_OUTPUT"
