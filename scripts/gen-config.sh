#!/usr/bin/env bash
set -euo pipefail

if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
    echo "Usage: $0 <TALOS_IP> <CLUSTER_NAME>"
    echo "Example: $0 192.168.50.220 joeckr_dev"
    exit 1
fi

TALOS_IP="$1"
CLUSTER_NAME="$2"

mkdir -p "$HOME/.talos/clusters/$CLUSTER_NAME"
cd "$HOME/.talos/clusters/$CLUSTER_NAME" || exit 1

talosctl gen config "$CLUSTER_NAME" "https://$TALOS_IP:6443" --output-dir . --force

cp talosconfig "$HOME/.talos/config"
export TALOSCONFIG="./talosconfig"

talosctl apply-config --insecure --nodes "$TALOS_IP" -f controlplane.yaml

talosctl config endpoint "$TALOS_IP"
talosctl config node "$TALOS_IP"
talosctl config context "$CLUSTER_NAME"
