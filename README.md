# lab-talos-cluster

[![CI](https://github.com/joeckr/lab-talos-cluster/actions/workflows/lint.yml/badge.svg)](https://github.com/joeckr/lab-talos-cluster/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A dedicated "enterprise-adjacent" home lab repository for deploying, documenting, operating, and extending an open-source [Talos Linux](https://www.talos.dev/) Kubernetes cluster running virtualized on [Proxmox VE](https://www.proxmox.com/en/proxmox-virtual-environment/overview).

> [!NOTE]
> **Project Status & Architecture Philosophy: "Enterprise Adjacent"**
> This repository is built as an **enterprise-adjacent** homelab. It adheres to enterprise production standards by avoiding dependencies on proprietary software or components that require commercial/business licenses (such as enterprise SaaS management layers).
>
> *Note on Talos Omni*: [Talos Omni](https://omni.siderolabs.com/) provides a managed web UI and WireGuard mesh (SideroLink) that is free for personal/homelab use. If you are building a personal cluster and want automated onboarding via a GUI, Omni is a great option. However, because commercial/enterprise use of Omni requires a paid business license, this repository intentionally standardizes on native, open-source Talos Linux operations (`talosctl`, declarative machine configs) to mirror true license-free enterprise architectures.

---

## Overview & Scope

The purpose of this repository is to serve as the single source of truth for:

- **Declarative Talos Linux Management**: Utilizing native `talosctl`, the Talos Image Factory, and declarative YAML machine configurations (`controlplane.yaml`, `worker.yaml`, and config patches) for end-to-end cluster lifecycle operations.
- **Cluster Documentation**: Node topology, configuration patch sets, Talos machine configurations, and day-2 operations.
- **Proxmox VE & VM Hardening**: Documenting best practices for provisioning and hardening the underlying Proxmox VE hypervisor and Talos VM instances (virtual hardware settings, networking bridges, storage, and security configurations).
- **Helm Charts (`charts/`)**: Developing, packaging, and maintaining custom and upstream-extended Helm charts configured for secure, rootless operation.
- **Automation & Scripting (`scripts/`)**: Shell scripts and tooling for bootstrap workflows, cluster lifecycle management, maintenance, and `talosctl` / `kubectl` operations.
- **Open-Source Infrastructure**: Ensuring all cluster operations run on open-source, vendor-neutral components with zero vendor lock-in.

---

## Architecture

```text
┌────────────────────────────────────────────────────────┐
│         Management Workstation / CI Automation         │
│  (talosctl, kubectl, helm, Declarative Machine Configs)│
└──────────────────────────┬─────────────────────────────┘
                           │ Talos API (mTLS / Port 50000)
                           │ Kubernetes API (TLS / Port 6443)
┌──────────────────────────▼─────────────────────────────┐
│                      Proxmox VE                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Hardened Virtual Machine(s)                      │  │
│  │  ┌────────────────────────────────────────────┐  │  │
│  │  │ Talos Linux (Immutable, API-managed OS)    │  │  │
│  │  │  ┌──────────────────────────────────────┐  │  │  │
│  │  │  │ Kubernetes Cluster                   │  │  │  │
│  │  │  │  - Hardened Helm workloads (charts/) │  │  │  │
│  │  │  │  - Ingress, CNI, & Services          │  │  │  │
│  │  │  └──────────────────────────────────────┘  │  │  │
│  │  └────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

- **Management & Control**: Driven directly via `talosctl` over secure mutual TLS (mTLS on TCP port 50000) with declarative machine configs generated locally or via CI/CD.
- **Operating System**: [Talos Linux](https://www.talos.dev/) — an immutable, secure, and minimal Linux distribution designed specifically for Kubernetes (no SSH, no shell, fully API-driven via `talosctl`).
- **Hypervisor**: [Proxmox VE](https://www.proxmox.com/) — hosting Talos control-plane and worker VMs with hardened virtual hardware configurations.
- **Operations & Tooling**: Driven via `talosctl`, `kubectl`, and `helm`.

---

## Directory Structure

```text
.
├── .github/
│   ├── FUNDING.yml              # Sponsorship configuration
│   └── workflows/
│       ├── lint.yml             # actionlint, commitlint, shellcheck
│       ├── release.yml          # SemVer tagging, GitHub releases, and Helm OCI publishing
│       ├── security.yml         # betterleaks secrets scanning and zizmor audit
│       └── test_release.yml     # PR dry-run tests for Helm and Semantic releases
├── charts/                      # Helm charts for cluster workloads & extensions
│   └── lab-cluster/             # Starter Helm chart (hardened, rootless defaults)
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── config/                      # Declarative cluster & machine configuration patches
│   └── controlplane-patch.yaml  # PSS restricted admission & control-plane workload scheduling
├── guides/                      # Step-by-step sequential setup & operational guides
│   ├── README.md                # Guide index & status overview
│   ├── 00-prereqs.md            # Workstation tooling, Proxmox & Talos prerequisites
│   ├── 01-proxmox-setup.md      # Proxmox host setup, clustering, and hardening
│   └── 02-install-talos.md      # Talos boot media, VM provisioning, machine configs & bootstrap
├── scripts/                     # Operational, provisioning, and maintenance scripts
│   ├── after-config.sh          # Control-plane bootstrap trigger
│   ├── apply-worker.sh          # Worker node configuration application & join watcher
│   ├── gen-config.sh            # Talos cluster config generator & initial CP apply
│   ├── kube-config.sh           # Kubeconfig retrieval and node connectivity verification
│   └── patch-controlplane.sh    # Declarative control-plane patch application
├── hk.pkl                       # Fast git hooks (hk) configuration
├── mise.toml                    # Tool version management & mise tasks
└── README.md
```

---

## Tooling & Local Setup

This repository uses [`mise`](https://mise.jdx.dev/) for deterministic tool management and [`hk`](https://hk.jdx.dev/) for pre-commit hooks.

### 1. Prerequisites

Ensure `mise` is installed on your local workstation:

```bash
# Verify mise installation
mise --version
```

### 2. Bootstrap Environment

Install project tools and register git hooks:

```bash
# Install tools and configure git hooks
mise run install

# Run repository linting and compliance checks
mise run check
```

---

## Development Workflows

### Helm Chart Development & Validation

All Helm charts live under `charts/`. CI automatically checks, packages, and publishes charts to GitHub Container Registry (GHCR) as OCI artifacts.

```bash
# Build Helm chart dependencies
mise run helm-d

# Recursively lint all charts under charts/
mise run helm-l

# Template rendering verification
helm template lab-cluster charts/lab-cluster/

# Scan files and manifests for vulnerabilities with Trivy
mise run trivy-fs
```

### Testing on Cluster

Deploy charts against the active Kubernetes context:

```bash
# Install or upgrade chart
helm upgrade --install lab-cluster charts/lab-cluster/

# Verify status
kubectl get pods,svc,ingress -l app=lab-service

# Teardown release
helm uninstall lab-cluster
```

---

## Mise Tasks Reference

| Task | Description | Command |
|---|---|---|
| `install` | Install tools and set up git hooks | `hk install --mise` |
| `check` (or `hk`) | Run all linters and hook checks across the repo | `hk check --all` |
| `helm-d` | Build Helm chart dependencies across all charts | `find charts -name "Chart.yaml" -exec dirname {} + \| xargs -n1 helm dependency build` |
| `helm-l` | Recursively lint all Helm charts under `charts/` | `find charts -name "Chart.yaml" -exec dirname {} + \| xargs helm lint` |
| `trivy-fs` | Scan repository filesystem for security vulnerabilities | `trivy fs .` |

---

## Security & Hardening Posture

1. **Talos OS & Cluster Security**:
   - Immutable root filesystem and minimal attack surface.
   - Host administration executed strictly via authenticated gRPC APIs over mutual TLS (mTLS on TCP port 50000) — no interactive shell, SSH daemon, or console credentials.
   - Client authentication and role delegation enforced via `talosconfig` and `kubeconfig`.
2. **Pod Security Standards (PSS)**:
   - Chart templates enforce `Restricted` Kubernetes Pod Security Standards out of the box:
     - Non-root execution (`runAsNonRoot: true`, `readOnlyRootFilesystem: true`).
     - Dropping all capabilities (`capabilities.drop: ["ALL"]`).
     - Default seccomp profile (`seccompProfile.type: RuntimeDefault`).
     - Disabled privilege escalation (`allowPrivilegeEscalation: false`).
     - Safe service account token mounting (`automountServiceAccountToken: false`).
3. **Hypervisor & VM Hardening (Proxmox VE)**:
   - Isolation of VM networks with dedicated VLANs/bridges.
   - Hardened QEMU/KVM virtual machine configurations.
   - Documentation of host OS hardening guidelines and storage access restrictions.

---

## Roadmap & Planning

- [x] **Proxmox VE Setup & Hardening Guide**: Documented hypervisor installation, clustering, storage, and host hardening in [`guides/01-proxmox-setup.md`](guides/01-proxmox-setup.md).
- [x] **Talos Installation & Bootstrap Guide**: Documented Talos Image Factory, VM provisioning, declarative machine configurations, and cluster bootstrapping in [`guides/02-install-talos.md`](guides/02-install-talos.md).
- [x] **Talos Node Configurations & Patches**: Declarative overlays (`config/controlplane-patch.yaml`) and lifecycle automation scripts (`scripts/`) for control-plane and worker nodes.
- [ ] **Cluster Networking & Ingress**: Defining CNI (e.g., Cilium or Flannel) setup and Ingress/Gateway API configurations.
- [ ] **Helm Chart Library Expansion**: Adding workload charts and extending upstream charts for home lab services.

---

## Conventional Commits & Releases

Commits must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:
- `feat:` -> Triggers a **minor** release (e.g., `v0.1.0` -> `v0.2.0`).
- `fix:` -> Triggers a **patch** release (e.g., `v0.1.0` -> `v0.1.1`).
- `feat!:` -> Triggers a **major** release.
- `chore:`, `docs:`, `ci:`, `test:`, `refactor:` -> Maintenance updates without a release bump.

Upon pushing to `main`, GitHub Actions automatically generates tags, creates releases, and packages Helm charts to GHCR.

---

## Support

If you find this project useful, consider supporting my work on [Ko-fi](https://ko-fi.com/joeckr):

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/joeckr)

## License

This project is licensed under the [MIT License](LICENSE).
