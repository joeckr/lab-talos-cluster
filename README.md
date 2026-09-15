# Talos Linux Cluster Source of Truth

This repository is a source of truth for setting things up in Talos Linux. It includes installation and setup scripts, as well as Helm charts for managing services in the cluster.

---

## Features

- **Installation Scripts (`scripts/`)**:
  - `init-talosctl.sh`: Initializes Talos CLI and bootstraps the cluster.
  - `install-ingress-nginx.sh`: Helper script to install ingress-nginx namespace, labels, and Helm chart.
  - `install-pvc-longhorn.sh`: Advanced helper script to install required Talos system extensions for Longhorn, patch machine configurations, and deploy the `pvc-longhorn` Helm chart.
- **Helm Charts (`charts/`)**:
  - Contains Helm wrappers and definitions for essential cluster services.
  - Currently includes `ingress-nginx` and `pvc-longhorn`.
- **Docker Compose (`docker-compose.yml`)**:
  - Spin up and test a lab service locally without requiring a cluster.
- **Environment & Tooling (`mise` & `prek`)**:
  - `mise.toml`: Tool version management (`helm`, `gitleaks`, `addlicense`, `trivy`, `actionlint`, `shellcheck`, `zizmor`) and convenient task aliases.
  - `prek.toml`: Fast git hooks enforcing Conventional Commits, branch protection, secrets scanning, recursive Helm linting across all charts, workflow linting (`actionlint`), script linting (`shellcheck`), and security audits (`zizmor`).
- **GitHub Actions CI (`.github/workflows/`)**:
  - Reusable workflows powered by [`joeckr/ci-templates`](https://github.com/joeckr/ci-templates):
    - `actionlint`: Lints GitHub Actions workflow syntax.
    - `zizmor`: Security audit of GitHub Actions workflows.
    - `shellcheck`: Lints shell scripts.
    - `commitlint`: Enforces Conventional Commits specification.
    - `gitleaks`: Scans commits and PRs for secret leaks.
    - `helm`: Recursively discovers, packages, and publishes Helm charts under `charts/` to GitHub Container Registry (GHCR) as OCI artifacts.
    - `semantic`: Automated Semantic Versioning, git tagging, and release notes.

---

## Directory Structure

```text
.
├── .github/
│   └── workflows/
│       ├── actionlint.yml       # Lints workflow files
│       ├── commitlint.yml       # Validates conventional commit messages
│       ├── gitleaks.yml         # Scans for credential leaks
│       ├── helm.yml             # Packages and pushes Helm charts to GHCR
│       ├── semantic.yml         # SemVer tagging and GitHub releases
│       ├── shellcheck.yml       # Shell script linting
│       ├── test_helm.yml        # PR dry-run test for Helm packaging
│       ├── test_semantic.yml    # PR dry-run test for Semantic Versioning
│       └── zizmor.yml           # Security audit for workflows
├── charts/
│   ├── ingress-nginx/           # Helm wrapper chart for ingress-nginx
│   └── pvc-longhorn/            # Helm wrapper chart for Longhorn
├── scripts/
│   ├── init-talosctl.sh         # Initializes talosctl and bootstraps cluster
│   ├── install-ingress-nginx.sh # Installs ingress-nginx
│   └── install-pvc-longhorn.sh  # Upgrades Talos extensions and installs Longhorn
├── docker-compose.yml           # Local lab service definition
├── mise.toml                    # Mise tools and tasks
├── prek.toml                    # Prek git hooks
└── README.md
```

---

## Quickstart

### 1. Bootstrap Local Environment

Ensure [`mise`](https://mise.jdx.dev/) and [`prek`](https://github.com/j178/prek) are installed:

```bash
# Verify environment and install git hooks
mise run install
```

### 2. Initialize Talos Cluster

Use the initialization script to bootstrap your cluster. You will need to provide the target node's IP address:

```bash
./scripts/init-talosctl.sh <node-ip>
```

### 3. Deploy Essential Services

Once the cluster is bootstrapped and your kubeconfig is configured, you can deploy the necessary components:

```bash
# Install Longhorn and required Talos extensions
./scripts/install-pvc-longhorn.sh

# Install Ingress NGINX
./scripts/install-ingress-nginx.sh
```

---

## Conventional Commits & Releases

Commits must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:
- `feat: add new feature` -> Triggers a **minor** release.
- `fix: resolve issue` -> Triggers a **patch** release.
- `feat!: breaking change` -> Triggers a **major** release.
- `chore:`, `docs:`, `ci:`, `test:`, `refactor:` -> Maintenance changes (no release bump).

Upon merging to `main`, the `semantic.yml` workflow automatically computes the next version, creates a Git tag, and publishes a GitHub Release.
