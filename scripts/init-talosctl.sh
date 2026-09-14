#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Usage: $0 <command>"
    exit 0
fi

VERSION=$(talosctl version --insecure --nodes "$1" | grep "error")
echo "Version: $VERSION"

if [ -n "$VERSION" ]; then
    echo "Error: $VERSION"
    exit 1
fi

talosctl gen config my-cluster https://"$1":6443
talosctl apply-config --insecure --nodes "$1" --file controlplane.yaml

talosctl config merge ./talosconfig
talosctl config endpoints "$1"
talosctl config node "$1"

talosctl bootstrap

talosctl kubeconfig ~/.kube/config --force-context-name talos-cluster

TEST=$(kubectl config get-contexts | grep "talos-cluster")
if [ -z "$TEST" ]; then
    echo "Error: talos-cluster not found in kubeconfig..."
    echo "To fix try something like: 'kubectl config rename-context admin@my-cluster talos-cluster'"
fi
