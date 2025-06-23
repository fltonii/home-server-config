#!/bin/bash
set -e

# === Parse arguments ===
NAME="$1"
LOG_PATH="$2"
LOKI_URL="$3"

# === Validate input ===
if [[ -z "$NAME" || -z "$LOG_PATH" || -z "$LOKI_URL" ]]; then
  echo "Usage: $0 <service_name> \"<log_path>\" <loki_url>"
  exit 1
fi

# === Paths ===
REPO_ROOT="$(dirname "$(realpath "$0")")/.."
TEMPLATE_DIR="$REPO_ROOT/promtail"
OUTPUT_DIR="$REPO_ROOT/$NAME"
CONFIG_OUTPUT="$OUTPUT_DIR/promtail.yaml"
SERVICE_OUTPUT="$OUTPUT_DIR/promtail.service"

# === Create output dir ===
mkdir -p "$OUTPUT_DIR"

# === Generate promtail.yaml ===
sed \
  -e "s|__NAME__|$NAME|g" \
  -e "s|__HOST__|$NAME.home|g" \
  -e "s|__LOG_PATH__|$LOG_PATH|g" \
  -e "s|__LOKI_URL__|$LOKI_URL|g" \
  "$TEMPLATE_DIR/promtail.template.yaml" > "$CONFIG_OUTPUT"

# === Generate promtail.service ===
sed \
  -e "s|__SERVICE_NAME__|promtail|g" \
  -e "s|__BINARY_PATH__|/opt/promtail|g" \
  -e "s|__CONFIG_PATH__|/etc/promtail/promtail.yaml|g" \
  "$TEMPLATE_DIR/promtail.service.template" > "$SERVICE_OUTPUT"

echo "✅ Generated config in $OUTPUT_DIR:"
echo "  - promtail.yaml"
echo "  - promtail.service"
