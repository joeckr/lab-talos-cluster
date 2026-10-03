# Cluster Guides

Step-by-step guides for standing up, configuring, and operating the Talos Linux Kubernetes cluster with Talos Omni and Proxmox VE.

## Sequential Guides

| Step | Guide | Description | Status |
|:---:|---|---|:---:|
| `00` | [00-prereqs.md](00-prereqs.md) | Local tooling, Proxmox requirements, Omni account, and network planning | Complete |
| `01` | [01-proxmox-setup.md](01-proxmox-setup.md) | Proxmox VE installation, repositories, clustering, storage, and host hardening | Complete |
| `02` | `02-omni-machine-registration.md` | Omni installation media / boot ISO and node onboarding | Planned |
| `03` | `03-cluster-bootstrap.md` | Cluster definition, machine allocation, config patches, and initial bootstrap | Planned |
| `04` | `04-cni-and-networking.md` | CNI configuration (Cilium/Flannel) and network policies | Planned |
| `05` | `05-storage-and-csi.md` | Persistent storage integration (CSI driver setup) | Planned |
| `06` | `06-ingress-and-workloads.md` | Ingress controllers, TLS certs, and deploying custom Helm charts | Planned |
| `90` | `90-troubleshooting-and-day2.md` | Day-2 operations, Talos upgrades, etcd maintenance, and runbooks | Planned |
