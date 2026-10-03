# 00 - Prerequisites & Setup Planning

This guide covers workstation tooling, infrastructure requirements, Talos Omni access, and IP/network planning required before provisioning nodes in Proxmox VE.

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
| [`omnictl`](https://omni.siderolabs.com/docs/how-to-guides/omnictl/) | Talos Omni management CLI | `omnictl version` |
| [`talosctl`](https://www.talos.dev/latest/introduction/getting-started/#talosctl) | Talos Linux administrative CLI | `talosctl version --client` |
| [`kubectl`](https://kubernetes.io/docs/tasks/tools/) | Kubernetes cluster interaction | `kubectl version --client` |
| [`helm`](https://helm.sh/) | Package manager for Kubernetes charts | `helm version` (managed via `mise`) |

> [!TIP]
> You can download `omnictl` directly from your Talos Omni instance web interface under your user account profile or from the Sidero Labs release portal.

---

## 2. Infrastructure Requirements (Proxmox VE)

### Lab Host Hardware (Current Environment)

The current lab infrastructure consists of **2 Proxmox VE hypervisor nodes** (repurposed custom desktop PCs), with plans to scale out with additional nodes in the future:

| Node | CPU | Memory | Storage Pools | Role / Notes |
|---|---|---|---|---|
| **PVE Node 1** | Intel Core i7-9700K (8C / 8T) | 32 GB RAM | • 1x 1 TB NVMe SSD<br>• 1x 1 TB SATA SSD | Reused desktop; initial control-plane & worker VM hosting |
| **PVE Node 2** | AMD Ryzen 9 5900X (12C / 24T) | 64 GB RAM | • 2x 2 TB drives | Reused desktop; high-capacity compute and storage pool |

> [!NOTE]
> **Cluster Expansion**:
> Initial cluster VMs are distributed across these 2 physical hosts. Additional Proxmox VE nodes will be incorporated over time as capacity needs expand and to achieve multi-node hypervisor quorum.

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

## 3. Talos Omni Prerequisites

### Deployment Model: SaaS vs. Self-Hosted

This lab environment is currently being developed and operated using **[Talos Omni SaaS](https://omni.siderolabs.com/)**:

- **Omni SaaS (Current Setup)**:
  - **Free for Homelab / Personal Use**: Sidero Labs provides a generous free community tier for personal and homelab clusters, removing the need to manage a separate control-plane cluster.
  - Quick setup with zero infrastructure overhead. Register and log in at [omni.siderolabs.com](https://omni.siderolabs.com/).
- **Self-Hosted Option**:
  - Omni can also be self-hosted on-premises (in an existing Kubernetes cluster or dedicated VM) if you require total local control or air-gapped operations.
  - Review the [Talos Omni Self-Hosting Guide](https://omni.siderolabs.com/docs/how-to-guides/install-omni/) for architectural requirements and deployment steps.

> [!TIP]
> For general guides, machine classes, and cluster templates, consult the [Official Talos Omni Documentation](https://omni.siderolabs.com/docs/).

### Setup & Authentication Steps

1. **Omni Account & Console Access**:
   - Log in to your [Talos Omni Console](https://omni.siderolabs.com/).
2. **Omni Service Account / omnictl Config**:
   - Authenticate `omnictl` on your local management workstation:
     ```bash
     # Configure context for Omni SaaS (default API endpoint: https://api.omni.siderolabs.io)
     omnictl config set-context lab-cluster --api-endpoint https://api.omni.siderolabs.io
     omnictl login
     ```

---

## Next Steps

Once prerequisites and workstation tooling are complete, proceed to:
- **[01-proxmox-setup.md](01-proxmox-setup.md)** (Proxmox VE host installation, clustering, and storage configuration)
