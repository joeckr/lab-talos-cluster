#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Required CLI tools
for cmd in talosctl kubectl helm curl jq; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Error: $cmd is required but not installed." >&2; exit 1; }
done

get_talos_version() {
  local ver
  # talosctl get version supports -o json
  ver=$(talosctl get version -o json 2>/dev/null | jq -r '.spec.version // empty' | head -n 1)
  # Fallback to parsing talosctl version plain text output
  if [[ -z "$ver" ]]; then
    ver=$(talosctl version 2>/dev/null | awk '/Server:/{flag=1} flag && /Tag:/{print $2; exit}')
  fi
  echo "$ver"
}

get_schematic_id() {
  local schematic_payload
  schematic_payload=$(cat <<'EOF'
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/iscsi-tools
      - siderolabs/util-linux-tools
EOF
)

  curl -sS -X POST \
    -H "Content-Type: application/yaml" \
    --data "${schematic_payload}" \
    https://factory.talos.dev/schematics | jq -r '.id'
}

has_required_extensions() {
  local ext
  ext=$(talosctl get extensions -o json 2>/dev/null | jq -r '.. | .metadata?.id? // empty' 2>/dev/null || true)
  if echo "$ext" | grep -q "iscsi-tools" && echo "$ext" | grep -q "util-linux-tools"; then
    return 0
  fi
  return 1
}

echo "==> Resolving node version from current context..."
TALOS_VERSION=$(get_talos_version)
if [[ -z "${TALOS_VERSION}" ]]; then
  echo "Error: Could not determine Talos version. Verify your active talosconfig context has a target node set." >&2
  exit 1
fi
echo "    Detected Talos version: ${TALOS_VERSION}"

echo "==> Checking if required Talos system extensions are already installed..."
if has_required_extensions; then
  echo "    System extensions (iscsi-tools, util-linux-tools) are already installed. Skipping Talos upgrade."
else
  echo "==> Fetching Longhorn schematic ID from Talos Image Factory..."
  SCHEMATIC_ID=$(get_schematic_id)
  if [[ -z "${SCHEMATIC_ID}" || "${SCHEMATIC_ID}" == "null" ]]; then
    echo "Error: Failed to retrieve schematic ID from factory.talos.dev." >&2
    exit 1
  fi
  echo "    Resolved Schematic ID:  ${SCHEMATIC_ID}"

  INSTALLER_IMAGE="factory.talos.dev/installer/${SCHEMATIC_ID}:${TALOS_VERSION}"
  echo "==> Target installer image: ${INSTALLER_IMAGE}"

  echo "==> Staging machine configuration (extraMounts & allowSchedulingOnControlPlanes) prior to reboot..."
  cat <<EOF | talosctl patch machineconfig --mode staged --patch @/dev/stdin
cluster:
  allowSchedulingOnControlPlanes: true
machine:
  kubelet:
    extraMounts:
      - destination: /var/lib/longhorn
        type: bind
        source: /var/lib/longhorn
        options:
          - bind
          - rshared
          - rw
EOF

  echo "==> Upgrading Talos node with system extensions (node will reboot)..."
  talosctl upgrade \
    --image "${INSTALLER_IMAGE}" \
    --wait

  echo "==> Waiting for Kubernetes node to become Ready..."
  kubectl wait --for=condition=Ready node --all --timeout=180s
fi

echo "==> Verifying extensions..."
talosctl get extensions

echo "==> Ensuring machine configuration is applied..."
cat <<EOF | talosctl patch machineconfig --mode auto --patch @/dev/stdin
cluster:
  allowSchedulingOnControlPlanes: true
machine:
  kubelet:
    extraMounts:
      - destination: /var/lib/longhorn
        type: bind
        source: /var/lib/longhorn
        options:
          - bind
          - rshared
          - rw
EOF

echo "==> Creating longhorn-system namespace with privileged Pod Security Admission..."
helm repo add longhorn https://charts.longhorn.io && helm repo update longhorn
kubectl create namespace longhorn-system --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace longhorn-system \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/audit=privileged \
  pod-security.kubernetes.io/warn=privileged \
  --overwrite

echo "==> Building Helm dependencies for pvc-longhorn..."
helm dependency build "${REPO_ROOT}/charts/pvc-longhorn"

echo "==> Installing / upgrading Longhorn Helm release..."
helm upgrade --install longhorn "${REPO_ROOT}/charts/pvc-longhorn" -n longhorn-system

echo "==> Waiting for Longhorn manager daemonset to be created..."
until kubectl get daemonset/longhorn-manager -n longhorn-system >/dev/null 2>&1; do
  sleep 2
done

echo "==> Waiting for Longhorn manager daemonset..."
kubectl rollout status daemonset/longhorn-manager -n longhorn-system --timeout=300s

echo "==> Longhorn deployment complete. Pod status:"
kubectl get pods -n longhorn-system
