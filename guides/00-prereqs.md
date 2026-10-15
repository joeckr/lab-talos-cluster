# 00 - Prerequisites & Setup Planning

This guide covers workstation tooling, infrastructure requirements, Talos Linux prerequisites, and IP/network planning required before provisioning nodes in Proxmox VE.

---

## 1. Local Workstation Tooling

> [!TIP]
> **macOS Workstation Provisioning via Dotfiles**:
> For macOS management machines, all required CLIs, shell utilities, and environment configurations are maintained in the [`joeckr/dotfiles`](https://github.com/joeckr/dotfiles) repository. Refer to that repository to bootstrap or synchronize your macOS workstation tooling.

### Core Package & Tool Management (`mise`)

This repository also includes a [mise.toml](../mise.toml) configuration that manages repository-specific developer tools, linters, and git hooks:

```bash
# Verify mise is installed
mise --version

# Install repository dependencies and git hooks
mise run install
```

### Essential CLIs

| Tool | Purpose | Installation / Verification |
|---|---|---|
| [`talosctl`](https://www.talos.dev/latest/introduction/getting-started/#talosctl) | Talos Linux administrative CLI | `talosctl version --client` |
| [`kubectl`](https://kubernetes.io/docs/tasks/tools/) | Kubernetes cluster interaction | `kubectl version --client` |
| [`helm`](https://helm.sh/) | Package manager for Kubernetes charts | `helm version` (managed via `mise`) |

> [!TIP]
> **Installing `talosctl`**:
> On macOS via Homebrew:
> ```bash
> brew install siderolabs/tap/talosctl
> ```
> Or install directly from the Sidero Labs releases:
> ```bash
> curl -sL https://talos.dev/install | sh
> ```

---

## 2. Infrastructure Requirements (Proxmox VE)

### VM Sizing Baselines & Hardware Defaults

When provisioning Talos VMs on these hosts, follow these resource baselines and virtual hardware configurations:

- **Compute & Memory Budget**:
  - **Control-plane nodes**: Minimum 2 vCPUs, 2 GB RAM, 20 GB disk (3 nodes recommended for HA, or 1 for a compact lab).
  - **Worker nodes**: Minimum 2-4 vCPUs, 4-8 GB RAM, 40+ GB disk per node depending on workloads.
- **Virtual Hardware Defaults**:
  - **BIOS**: UEFI (OVMF) with `q35` machine type recommended.
  - **Disk Controller**: VirtIO SCSI single controller with `discard` enabled for SSD TRIM support.
  - **Network Interface**: VirtIO (`virtio-net`) device for maximum throughput.
  - **Processor Type**: `host` for best performance and CPU instruction passthrough.
- **Dedicated Bridge or VLAN**:
  - A designated bridge (e.g., `vmbr0`) or dedicated VLAN tag for cluster traffic isolation.

---

## 3. Talos Linux Architecture & Licensing

### Architectural Standard: Enterprise-Adjacent Homelab

This homelab is intentionally designed around an **"enterprise-adjacent"** operating standard:

- **Fully Open-Source & License-Free**: We avoid dependencies on software that requires commercial or business licenses in enterprise environments. All cluster operations rely strictly on the open-source [Talos Linux](https://www.talos.dev/) distribution, native `talosctl`, standard Kubernetes manifests, and open-source tooling.
- **Direct API & Declarative Configuration**: Machines are configured, bootstrapped, and upgraded using native `talosctl` commands and version-controlled declarative YAML configurations (`controlplane.yaml`, `worker.yaml`, and config patches).
- **Mutual TLS (mTLS) Security**: Host-level administrative communication runs directly between your workstation and the Talos OS nodes over gRPC on TCP port `50000`, authenticated via client certificates in `talosconfig`.

> [!NOTE]
> **A Note on Talos Omni for Personal Homelabs**:
> [Talos Omni](https://omni.siderolabs.com/) (both SaaS and self-hosted) is an excellent commercial product by Sidero Labs that features automated node registration, WireGuard overlay networking (SideroLink), and a clean web management dashboard.
>
> Sidero Labs generously provides a **free community tier for personal and homelab use**. If you prefer a managed web console and simplified node onboarding for personal projects, Omni is an option worth exploring.
>
> However, because Omni requires a commercial license in business settings, this repository intentionally adheres to native, open-source Talos Linux tooling to mirror true enterprise-grade, license-free production architectures.

### Network Ports & Endpoint Planning

Ensure the following ports and addresses are planned in your local network:

| Port / Protocol | Component | Purpose |
|---|---|---|
| `50000 / TCP` | Talos API (`apid`) | Administrative management via `talosctl` (mTLS) |
| `6443 / TCP` | Kubernetes API Server | Cluster administration via `kubectl` (TLS) |
| `2379-2380 / TCP` | `etcd` | Control-plane etcd consensus and peer traffic |
| `51871 / UDP` | WireGuard / KubeSpan (Optional) | Encrypted node-to-node overlay networking |

For high-availability clusters, plan a **Control Plane VIP** (Virtual IP) or a local DNS entry (e.g. `k8s.lab.internal`) that points to the control-plane node(s) on port `6443`. For initial setups, a designated control-plane IP or Talos-managed VIP can be configured in machine configs.

---

## Next Steps

Once prerequisites and workstation tooling are complete, proceed to:
- **[01-proxmox-setup.md](01-proxmox-setup.md)** (Proxmox VE host installation, clustering, and storage configuration)
