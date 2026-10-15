# Cluster Guides

Step-by-step guides for standing up, configuring, and operating the Talos Linux Kubernetes cluster with Proxmox VE.

## Sequential Guides

| Step | Guide | Description | Status |
|:---:|---|---|:---:|
| `00` | [00-prereqs.md](00-prereqs.md) | Local tooling, Proxmox requirements, Talos prerequisites, and network planning | Complete |
| `01` | [01-proxmox-setup.md](01-proxmox-setup.md) | Proxmox VE installation, repositories, clustering, storage, and host hardening | Complete |
| `02` | [02-install-talos.md](02-install-talos.md) | Talos boot media generation, Proxmox VM provisioning, machine configuration, and cluster bootstrap | Complete |
| `03` | `03-cni-and-networking.md` | CNI configuration (Cilium/Flannel) and network policies | Planned |
| `04` | `04-storage-and-csi.md` | Persistent storage integration (CSI driver setup) | Planned |
| `05` | `05-ingress-and-workloads.md` | Ingress controllers, TLS certs, and deploying custom Helm charts | Planned |
| `90` | `90-troubleshooting-and-day2.md` | Day-2 operations, Talos upgrades, etcd maintenance, and runbooks | Planned |
