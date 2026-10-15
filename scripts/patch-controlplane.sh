#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/controlplane-patch.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration patch file not found at $CONFIG_FILE"
    exit 1
fi

talosctl patch machineconfig --patch @"$CONFIG_FILE" "$@"
