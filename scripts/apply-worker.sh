#!/usr/bin/env bash
set -euo pipefail

if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
    echo "Usage: $0 <TALOS_IP> <CLUSTER_NAME>"
    echo "Example: $0 192.168.50.64 joeckr_dev"
    exit 1
fi

TALOS_IP="$1"
CLUSTER_NAME="$2"

CLUSTER_DIR="$HOME/.talos/clusters/$CLUSTER_NAME"
if [ ! -d "$CLUSTER_DIR" ]; then
    echo "Error: Directory $CLUSTER_DIR does not exist."
    exit 1
fi

cd "$CLUSTER_DIR" || exit 1

talosctl apply-config --insecure --nodes "$TALOS_IP" --file worker.yaml

kubectl get nodes -w
