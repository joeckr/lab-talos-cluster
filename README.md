# lab-talos-cluster

[![CI](https://github.com/joeckr/lab-talos-cluster/actions/workflows/lint.yml/badge.svg)](https://github.com/joeckr/lab-talos-cluster/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A dedicated home lab repository for deploying, documenting, operating, and extending a [Talos Linux](https://www.talos.dev/) Kubernetes cluster managed with [Talos Omni](https://omni.siderolabs.com/) and running virtualized on [Proxmox VE](https://www.proxmox.com/en/proxmox-virtual-environment/overview).

> [!NOTE]
> **Project Status: Active Work in Progress (WIP)**
> This project is in its early stages and will be an evolving workspace over time as cluster components, automation scripts, hardening guidelines, Omni configurations, and custom Helm charts are developed and tested.

---

## Overview & Scope

The purpose of this repository is to serve as the single source of truth for:

- **Cluster Management via Talos Omni**: Utilizing [Talos Omni](https://omni.siderolabs.com/) for automated machine registration, cluster lifecycle operations, configuration patch distribution, and secure management overlays.
- **Cluster Documentation**: Node topology, configuration patch sets, Talos machine configurations, and day-2 operations.
- **Proxmox VE & VM Hardening**: Documenting best practices for provisioning and hardening the underlying Proxmox VE hypervisor and Talos VM instances (virtual hardware settings, networking bridges, storage, and security configurations).
- **Helm Charts (`charts/`)**: Developing, packaging, and maintaining custom and upstream-extended Helm charts configured for secure, rootless operation.
- **Automation & Scripting (`scripts/`)**: Shell scripts and tooling for bootstrap workflows, cluster lifecycle management, maintenance, `omnictl`, and `talosctl` operations.
- **Future Architecture Exploration**: Monitoring the development of [Talos Director](https://www.siderolabs.com/) and evaluating whether to eventually transition from Omni once Director becomes generally available and matures.

---

## Architecture

```text
┌────────────────────────────────────────────────────────┐
│                   Talos Omni Plane                     │
│  (Machine Registration, WireGuard Mesh, Config Patches,│
│   Cluster Orchestration, omnictl & API endpoints)      │
└──────────────────────────┬─────────────────────────────┘
                           │ WireGuard (SideroLink) / gRPC
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

- **Management Plane**: [Talos Omni](https://omni.siderolabs.com/) — manages machine discovery, automated installation, cluster creation, node maintenance, and encrypted WireGuard overlay networking (SideroLink).
- **Operating System**: [Talos Linux](https://www.talos.dev/) — an immutable, secure, and minimal Linux distribution designed specifically for Kubernetes (no SSH, no shell, fully API-driven via `talosctl` and Omni).
- **Hypervisor**: [Proxmox VE](https://www.proxmox.com/) — hosting Talos control-plane and worker VMs with hardened virtual hardware configurations.
- **Operations & Tooling**: Driven via `omnictl`, `talosctl`, `kubectl`, and `helm`.
- **Future Evolution**: Evaluating Talos Director once released and stable to assess potential migration or architectural shifts from Omni.

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
├── guides/                      # Step-by-step sequential setup & operational guides
│   ├── README.md                # Guide index & status overview
│   ├── 00-prereqs.md            # Workstation tooling, Proxmox & Omni prerequisites
│   └── 01-proxmox-setup.md      # Proxmox host setup, clustering, and hardening
├── scripts/                     # Operational, provisioning, and maintenance scripts
│   └── template.sh              # Starter script placeholder
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

1. **Talos OS & Omni Security**:
   - Immutable root filesystem and minimal attack surface.
   - Node-to-Omni communication encrypted via WireGuard tunnels (SideroLink) and authenticated gRPC APIs (no interactive shell or SSH daemon).
   - Centralized RBAC and access delegation through `omnictl` and generated kubeconfig/talosconfig contexts.
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
- [ ] **Omni Machine Templates & Config Patches**: Documenting and versioning Omni machine configurations, cluster patches, and labels.
- [ ] **Talos Node Configurations**: Storing baseline machine configs and overlays for control-plane and worker nodes.
- [ ] **Cluster Networking & Ingress**: Defining CNI (e.g., Cilium or Flannel) setup and Ingress/Gateway API configurations.
- [ ] **Helm Chart Library Expansion**: Adding workload charts and extending upstream charts for home lab services.
- [ ] **Talos Director Assessment**: Monitoring Sidero Labs' Talos Director release and evaluating its viability as an alternative or evolution to Omni as it matures.

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
