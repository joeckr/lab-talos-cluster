#!/usr/bin/env bash
set -euo pipefail

if [ -z "${1:-}" ]; then
    echo "Usage: $0 <TALOS_IP>"
    echo "Example: $0 192.168.50.220"
    exit 1
fi

TALOS_IP="$1"

if talosctl version --nodes "$TALOS_IP" >/dev/null 2>&1 || talosctl version >/dev/null 2>&1; then
    echo "Talos API is available on $TALOS_IP"
    echo "Attempting bootstrap..."
    talosctl bootstrap --nodes "$TALOS_IP"
else
    echo "Talos API is not available on $TALOS_IP"
    exit 1
fi
