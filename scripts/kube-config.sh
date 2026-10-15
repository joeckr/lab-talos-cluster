#!/usr/bin/env bash
set -euo pipefail

talosctl kubeconfig ~/.kube/config

kubectl get nodes
