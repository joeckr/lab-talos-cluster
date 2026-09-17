# Talos Linux Cluster Source of Truth

This repository is a source of truth for setting things up in Talos Linux. It includes installation and setup scripts, as well as Helm charts for managing services in the cluster.

---

## Features

- **Installation Scripts (`scripts/`)**:
  - `init-talosctl.sh`: Initializes Talos CLI configuration, bootstraps the control plane node, and merges kubeconfig.
  - `install-ingress-nginx.sh`: Helper script to create the `ingress-nginx` namespace with privileged pod security labels, build dependencies, and install the `ingress-nginx` Helm chart.
  - `install-pvc-longhorn.sh`: Automated helper script to detect Talos version, generate custom Talos schematics with required system extensions (`iscsi-tools`, `util-linux-tools`), upgrade the node if needed, patch machine configs, and deploy the `pvc-longhorn` Helm chart.
- **Helm Charts (`charts/`)**:
  - Contains Helm wrappers and definitions for essential cluster services.
  - Currently includes `ingress-nginx` and `pvc-longhorn`.
- **Docker Compose (`docker-compose.yml`)**:
  - Spin up and test a lab service locally without requiring a cluster.
- **Environment & Tooling (`mise` & `hk`)**:
  - `mise.toml`: Tool version management (`helm`, `betterleaks`, `addlicense`, `trivy`, `actionlint`, `hadolint`, `shellcheck`, `zizmor`, `hk`, `pkl`, `tombi`, `yamllint`) and task aliases.
  - `hk.pkl`: Git hooks powered by `hk` (configured via Pkl) enforcing Conventional Commits, branch protection, secrets scanning (`betterleaks`), formatting & linting (`yamllint`, `tombi`, `actionlint`, `shellcheck`, `zizmor`, `hadolint`, `pkl`), license headers (`addlicense`), and recursive Helm chart linting (`helm lint`).
- **GitHub Actions CI (`.github/workflows/`)**:
  - Reusable workflows powered by [`joeckr/ci-templates`](https://github.com/joeckr/ci-templates):
    - `lint.yml`: Lints GitHub Actions syntax (`actionlint`), validates commit messages (`commitlint`), and lints shell scripts (`shellcheck`).
    - `security.yml`: Scans commits and pull requests for secrets (`betterleaks`) and audits workflows (`zizmor`).
    - `release.yml`: Automates Semantic Versioning, git tagging, GitHub release creation, and publishes packaged Helm charts to GitHub Container Registry (GHCR) as OCI artifacts.
    - `test_release.yml`: PR testing that validates Helm chart packaging (dry-run) and Semantic Release computation.

---

## Directory Structure

```text
.
├── .github/
│   └── workflows/
│       ├── lint.yml             # Workflow, commit, and shell script linting
│       ├── release.yml          # SemVer tagging, GitHub releases, and Helm GHCR publish
│       ├── security.yml         # Secret scanning (betterleaks) and workflow audit (zizmor)
│       └── test_release.yml     # PR dry-run test for Helm packaging and SemVer
├── charts/
│   ├── ingress-nginx/           # Helm wrapper chart for ingress-nginx
│   └── pvc-longhorn/            # Helm wrapper chart for Longhorn
├── scripts/
│   ├── init-talosctl.sh         # Initializes talosctl and bootstraps cluster
│   ├── install-ingress-nginx.sh # Installs ingress-nginx
│   └── install-pvc-longhorn.sh  # Upgrades Talos extensions and installs Longhorn
├── docker-compose.yml           # Local lab service definition
├── hk.pkl                       # Hk git hooks configuration (Pkl)
├── mise.toml                    # Mise tools and tasks
└── README.md
```

---

## Quickstart

### 1. Bootstrap Local Environment

Ensure [`mise`](https://mise.jdx.dev/) is installed:

```bash
# Install tools and set up hk git hooks
mise run install

# (Optional) Run all checks locally across the repository
mise run hk      # alias: mise run check
```

Other helpful `mise` tasks:
```bash
mise run helm-lint   # Recursively lint all Helm charts
mise run trivy-fs    # Scan filesystem with Trivy
mise run compose     # Start local Docker Compose lab
mise run logs        # Follow Docker Compose logs
mise run down        # Stop local Docker Compose lab
```

### 2. Initialize Talos Cluster

Use the initialization script to bootstrap your cluster. Provide the target node's IP address:

```bash
./scripts/init-talosctl.sh <node-ip>
```

### 3. Deploy Essential Services

Once the cluster is bootstrapped and your kubeconfig is configured, deploy the necessary components:

```bash
# Install Longhorn (with required Talos system extensions)
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

Commit messages are validated locally on commit via the `hk` `commit-msg` hook and in CI via `commitlint`.

Upon merging to `main`, the `release.yml` workflow automatically computes the next version, creates a Git tag, generates release notes, publishes a GitHub Release, and publishes Helm charts to GHCR. On pull requests, `test_release.yml` performs a dry-run to validate Helm packaging and preview release bumps.

## Support

If you find this project useful, consider supporting my work on [Ko-fi](https://ko-fi.com/joeckr):

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/joeckr)

## License

Please refer to the `LICENSE` file for details.
