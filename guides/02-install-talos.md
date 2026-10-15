# 02 - Install Talos Linux & Bootstrap Cluster

This guide walks through deploying [Talos Linux](https://www.talos.dev/) virtual machines on Proxmox VE, configuring them via native `talosctl`, applying declarative machine config patches, and bootstrapping the initial Kubernetes cluster without commercial or proprietary management planes.

---

## Architecture Context & Design Decisions

### Enterprise-Adjacent Standard

In enterprise environments, infrastructure tooling is subject to commercial licensing constraints, strict audit requirements, and vendor lock-in assessments. To emulate an **enterprise-adjacent** production standard, this lab intentionally uses:

1. **Native `talosctl` & Direct mTLS APIs**: All machine operations (config submission, rebooting, kernel parameter adjustments, and log inspection) communicate directly with the Talos API (`apid`) over TCP port `50000` via mutual TLS.
2. **Declarative Version-Controlled Configs**: Cluster topologies and machine states are defined through declarative YAML definitions (`controlplane.yaml`, `worker.yaml`, and config patches) stored in Git.
3. **No Commercial Licenses**: Completely open-source, eliminating dependencies on software requiring business licenses.

> [!NOTE]
> **A Note on Talos Omni for Personal Homelabs**:
> [Talos Omni](https://omni.siderolabs.com/) is an official SaaS / on-premises management platform from Sidero Labs that provides automated machine onboarding, an interactive web UI, and WireGuard mesh networking (SideroLink).
>
> Sidero Labs offers a **free community tier for personal and homelab use**. If you prefer a graphical interface and automated discovery for a personal lab, Omni is an excellent option.
>
> However, because Omni requires a commercial license in business environments, this guide standardizes on native, open-source Talos Linux tooling to preserve an enterprise-grade posture.

---

## 1. Talos Image Factory & Boot Media

Talos Linux is an immutable OS without a traditional package manager or interactive installer. Hardware drivers, kernel modules, and platform integrations are bundled directly into the boot image as **System Extensions**.

### Step 1.1: Generate Custom Talos ISO

Generate a tailored installation image from the [Talos Image Factory](https://factory.talos.dev/):

1. **Hardware Type**: Select `Bare-metal Machine`.
2. **Talos Version**: Select the latest stable release (e.g., `v1.14.2` at the time of writing).
3. **Architecture**: Select your target architecture (`amd64` vs `arm64`). Leave SecureBoot disabled unless your environment requires signed kernel validation.
4. **System Extensions**: At minimum, select:
   - `siderolabs/qemu-guest-agent`: Essential for Proxmox VE integration (reports guest IP addresses, node health, and enables clean ACPI power events).
   - Additional extensions may be added depending on host hardware:
     - GPU compute acceleration: `siderolabs/nvidia-container-toolkit`
     - Storage drivers: `siderolabs/iscsi-tools` or `siderolabs/util-linux-tools` for storage CSI drivers
5. Download the `.iso` file, or copy the direct ISO URL.

### Step 1.2: Upload ISO to Proxmox VE

1. In the Proxmox VE web interface, navigate to the target storage pool configured for ISO storage (typically `local` under each node).
2. Select **ISO Images**, then either:
   - Click **Upload** and select the downloaded ISO from your local workstation, or
   - Click **Download from URL** and paste the direct ISO URL from the Talos Image Factory.
3. Ensure the ISO is accessible on each Proxmox node where Talos VMs will be scheduled.

---

## 2. Provisioning Proxmox Virtual Machines

Create the virtual machines on your Proxmox VE hosts using the following settings:

1. Click **Create VM** in the top-right corner of the Proxmox UI.
2. **General**:
   - **Node**: Select target Proxmox node.
   - **VM ID**: Specify a unique VM ID (e.g., `100`, `101`, etc.).
   - **Name**: Assign a hostname (e.g., `talos-cp-01`, `talos-worker-01`).
   - **Start at Boot**: Checked.
3. **OS**:
   - **Storage**: Storage pool containing your Talos ISO.
   - **ISO Image**: Select your customized Talos Linux ISO.
   - **Type**: `Linux`, Version `6.x - 2.6 Kernel`.
4. **System**:
   - **Machine**: `q35`
   - **BIOS**: `OVMF (UEFI)`
   - **EFI Storage**: Main NVMe or SSD storage pool (uncheck "Pre-Enroll Keys").
   - **SCSI Controller**: `VirtIO SCSI`
   - **QEMU Agent**: Checked.
5. **Disks**:
   - **Bus/Device**: `SCSI`
   - **Storage**: Target NVMe / SSD storage pool.
   - **Disk Size**: Allocate 20–40 GB for control-plane nodes and 40–100+ GB for workers (ensure reserve headroom on physical storage pools in case nodes fail over).
   - **Discard**: Checked (enables SSD TRIM).
   - **SSD Emulation**: Checked.
   - **Backup**: Checked.
6. **CPU**:
   - **Sockets**: `1`
   - **Cores**: Allocate 2–4 cores per node (refer to sizing baselines in [00-prereqs.md](00-prereqs.md)).
   - **Type**: `host` (recommended for optimal performance and CPU feature passthrough).
7. **Memory**:
   - **Memory**: Allocate 4096–8192 MB per node (refer to [00-prereqs.md](00-prereqs.md)).
   - **Ballooning Device**: Unchecked (Talos strongly recommends disabling memory ballooning to prevent latency spikes and ensure etcd stability).
8. **Network**:
   - **Bridge**: `vmbr0` (or designated cluster bridge/VLAN).
   - **Model**: `VirtIO (paravirtualized)`.
9. **Confirm**: Review the settings and click **Finish**. Repeat for each control-plane and worker VM.

---

## 3. Static IP Configuration (DHCP Reservations)

Talos nodes require stable, deterministic IP addresses for internal communication, etcd consensus, and API access. Configuring DHCP reservations on your network router is the recommended homelab approach:

1. Start the VM and open the **Console** in the Proxmox web UI.
2. Under the VM's **Hardware** tab, double-click **Network Device** and copy the virtual MAC address. Alternatively, the Talos console dashboard displays the active IP and MAC address once booted.
3. Open your router's DHCP management interface and add a DHCP reservation binding the MAC address to your planned static IP (e.g., `192.168.50.220`).
4. Reboot the VM from Proxmox to verify it leases the reserved IP address.
5. Repeat for all control-plane and worker nodes.

---

## 4. Generate Machine Configurations & Initialize Control Plane

With the control-plane VM running and reachable, generate the cluster machine configurations and bootstrap the control plane using the repository automation scripts.

### Step 4.1: Generate Configurations & Apply Control Plane Config

Run `scripts/gen-config.sh`, providing the control-plane IP address and your desired cluster name:

```bash
# Usage: ./scripts/gen-config.sh <CONTROL_PLANE_IP> <CLUSTER_NAME>
./scripts/gen-config.sh 192.168.50.220 joeckr_dev
```

This script:
1. Creates a cluster configuration directory at `~/.talos/clusters/<CLUSTER_NAME>/`.
2. Runs `talosctl gen config` targeting the Kubernetes API endpoint (`https://<CONTROL_PLANE_IP>:6443`), producing `controlplane.yaml`, `worker.yaml`, and `talosconfig`.
3. Sets up your client `talosconfig` in `~/.talos/config` with active endpoints and default node targeting.
4. Applies `controlplane.yaml` to the target node via `talosctl apply-config --insecure`.

### Step 4.2: Bootstrap the Control Plane

Once the node applies the configuration, the Talos console prompt indicates that the node is waiting for bootstrap. Run `scripts/after-config.sh`:

```bash
# Usage: ./scripts/after-config.sh <CONTROL_PLANE_IP>
./scripts/after-config.sh 192.168.50.220
```

This script:
1. Validates that the Talos API (`apid`) is responding on TCP port `50000`.
2. Triggers `talosctl bootstrap` to initialize etcd consensus and launch core Kubernetes control-plane components.

---

## 5. Apply Talos Cluster Patches

By default, Talos taints control-plane nodes to prevent workload scheduling, and Kubernetes does not enforce Pod Security admission standards. This repository provides a declarative patch at `config/controlplane-patch.yaml` to configure:

1. **Control-Plane Workload Scheduling** (`/cluster/allowSchedulingOnControlPlanes: true`): Allows pods to run on control-plane nodes, ideal for compact or dev labs.
2. **Pod Security Standards (PSS) Admission Controller** (`/cluster/apiServer/admissionControl`): Enforces the `restricted` PSS profile across all namespaces, with exemptions configured for `kube-system`.

### Declarative Patching (Recommended)

Apply the patch using `scripts/patch-controlplane.sh`:

```bash
# Automatically applies config/controlplane-patch.yaml to the active control-plane node
./scripts/patch-controlplane.sh

# Or target a specific node explicitly
./scripts/patch-controlplane.sh --nodes 192.168.50.220
```

### Manual Interactive Editing (Alternative)

If you prefer to edit the configuration interactively:

```bash
talosctl edit mc --nodes <CONTROL_PLANE_IP> --mode=auto
```

- Locate `KubeAdmissionControlConfig` and set `enforce`, `audit`, and `warn` to `restricted` with versions set to `latest`, exempting `kube-system`.
- Locate `KubeNodeConfig` and remove the `taints` block if you wish to allow scheduling on control planes.
- Save and exit (`:wq`) to apply the configuration.

---

## 6. Retrieve Kubeconfig & Verify Control Plane

Retrieve the cluster administrative credentials (`kubeconfig`) and verify control-plane readiness using `scripts/kube-config.sh`:

```bash
./scripts/kube-config.sh
```

This runs `talosctl kubeconfig ~/.kube/config` and executes `kubectl get nodes`. Verify that the control-plane node reports `Ready`:

```text
NAME            STATUS   ROLES           AGE   VERSION
talos-rxi-uux   Ready    control-plane   23h   v1.37.1
```

---

## 7. Connect & Bootstrap Worker Nodes

Add worker nodes to the cluster using `scripts/apply-worker.sh`.

```bash
# Usage: ./scripts/apply-worker.sh <WORKER_IP> <CLUSTER_NAME>
./scripts/apply-worker.sh 192.168.50.64 joeckr_dev
```

This script:
1. Accesses `~/.talos/clusters/<CLUSTER_NAME>/worker.yaml`.
2. Applies the worker configuration to the target machine via `talosctl apply-config --insecure`.
3. Monitors the node join process with `kubectl get nodes -w`.

Repeat this command for each worker VM (e.g. `192.168.50.137`, `192.168.50.64`).

### Cluster Verification

Once all nodes are joined, inspect the entire cluster topology:

```bash
kubectl get nodes -o wide
```

Expected output:

```text
NAME            STATUS   ROLES           AGE     VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE          KERNEL-VERSION          CONTAINER-RUNTIME
talos-2ap-qqp   Ready    <none>          15m     v1.37.1   192.168.50.64    <none>        Talos (v1.14.2)   6.18.54-talos (amd64)   containerd://2.3.6
talos-in9-dk3   Ready    <none>          17m     v1.37.1   192.168.50.137   <none>        Talos (v1.14.2)   6.18.54-talos (amd64)   containerd://2.3.6
talos-rxi-uux   Ready    control-plane   23h     v1.37.1   192.168.50.220   <none>        Talos (v1.14.2)   6.18.54-talos (amd64)   containerd://2.3.6
```

---

## Next Steps

With your Talos Linux control-plane and worker nodes provisioned, bootstrapped, and reporting `Ready`, proceed to:
- **`03-cni-and-networking.md`** (Configuring CNI plugins, Cilium/Flannel, KubeSpan, and cluster network policies)
