# skeleton-lab-cluster

A starter skeleton repository tailored as a source of truth, documentation, and multiple Helm charts across different flavors of Kubernetes (vanilla Kubernetes, Talos, OpenShift, etc.) in a lab environment.

> **Note**: This repository intentionally **does NOT include a Dockerfile**. If a custom image build is required, use an OCI image repository (such as `skeleton-oci-modified`). Lab cluster repositories focus on cluster configuration, deployment definitions, documentation, and Helm charts.

---

## Features

- **Helm Charts (`charts/`)**:
  - Multi-chart repository layout supporting multiple charts across Kubernetes flavors and components.
  - Automated recursive chart discovery, linting, packaging, and publishing in CI.
  - Starter chart (`charts/lab-cluster`) with support for Kubernetes and OpenShift (Ingress vs. Routes).
  - Secure defaults: non-root execution (`runAsNonRoot: true`), `RuntimeDefault` seccomp profile, and dropping `ALL` capabilities.
  - Master and control-plane node tolerations for compact lab clusters.
- **Docker Compose (`docker-compose.yml`)**:
  - Spin up and test services locally without requiring a cluster.
  - Pre-configured with port forwarding and healthchecks.
- **Environment & Tooling (`mise` & `prek`)**:
  - `mise.toml`: Tool version management (`helm`, `gitleaks`, `addlicense`, `trivy`, `actionlint`) and convenient task aliases.
  - `prek.toml`: Fast git hooks enforcing Conventional Commits, branch protection, secrets scanning, recursive Helm linting across all charts, workflow linting (`actionlint`), and security audits (`zizmor`).
- **GitHub Actions CI (`.github/workflows/`)**:
  - Reusable workflows powered by [`joeckr/ci-templates`](https://github.com/joeckr/ci-templates):
    - `actionlint`: Lints GitHub Actions workflow syntax.
    - `zizmor`: Security audit of GitHub Actions workflows.
    - `commitlint`: Enforces Conventional Commits specification.
    - `gitleaks`: Scans commits and PRs for secret leaks.
    - `helm`: Recursively discovers, packages, and publishes Helm charts under `charts/` to GitHub Container Registry (GHCR) as OCI artifacts (with PR dry-run preview).
    - `semantic`: Automated Semantic Versioning, git tagging, and release notes (with PR dry-run preview).

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
│       ├── test_helm.yml        # PR dry-run test for Helm packaging
│       ├── test_semantic.yml    # PR dry-run test for Semantic Versioning
│       └── zizmor.yml           # Security audit for workflows
├── charts/
│   └── lab-cluster/             # Starter Helm chart (add additional charts/wrappers here)
│       ├── Chart.yaml           # Helm chart definition
│       ├── values.yaml          # Default configuration values
│       ├── .helmignore          # Ignore rules for chart packaging
│       └── templates/
│           ├── deployment.yaml  # Workload deployment
│           ├── service.yaml     # Kubernetes Service
│           ├── ingress.yaml     # Kubernetes Ingress
│           └── route.yaml       # OpenShift Route
├── scripts/
│   └── template.sh              # Starter script placeholder
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

### 2. Local Experimentation (Docker Compose)

Start the local lab service:

```bash
# Start container in detached mode
mise run compose

# Check status and logs
docker compose ps
mise run logs

# Stop container
mise run down
```

### 3. Kubernetes / Helm Experimentation

#### Lint and Template Locally
```bash
# Recursively lint all charts under charts/
mise run helm-lint

# Or via command line directly
find charts -name "Chart.yaml" -exec dirname {} + | xargs helm lint

# Test OpenShift Route rendering
helm template lab-cluster charts/lab-cluster/ --set ingress.enabled=true --set ingress.route=true
```

---

## Conventional Commits & Releases

Commits must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:
- `feat: add new feature` -> Triggers a **minor** release (e.g., `v0.1.0` -> `v0.2.0`).
- `fix: resolve issue` -> Triggers a **patch** release (e.g., `v0.1.0` -> `v0.1.1`).
- `feat!: breaking change` -> Triggers a **major** release.
- `chore:`, `docs:`, `ci:`, `test:`, `refactor:` -> Maintenance changes (no release bump).

Upon merging to `main`, the `semantic.yml` workflow automatically computes the next version, creates a Git tag, and publishes a GitHub Release. The `helm.yml` workflow recursively discovers all charts under `charts/`, packages each chart, and pushes them to GHCR.
