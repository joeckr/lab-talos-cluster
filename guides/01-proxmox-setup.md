# 01 - Proxmox VE Host Setup & Initial Configuration

## Introduction

This guide walks through the installation, initial configuration, and clustering of the bare-metal Proxmox VE hypervisor hosts for this lab. By the end of this guide, your physical hosts will be installed, updated with free community repositories, assigned static IP reservations, clustered into a unified Datacenter, and configured with dedicated storage pools.

---

## Download and Install Proxmox VE

1. **Download the ISO**:
   - Download the latest Proxmox VE ISO installer from the official [Proxmox Downloads](https://www.proxmox.com/en/downloads) page.

2. **Create Bootable Media**:
   - Flash the ISO to a USB flash drive using [Balena Etcher](https://etcher.balena.io/) or [Ventoy](https://www.ventoy.net/).
   - *(Ventoy is convenient if you maintain multiple operating systems on a single drive; otherwise, Balena Etcher provides a straightforward single-image flash).*

3. **Verify BIOS / UEFI Settings**:
   - Insert the bootable media into your target bare-metal machine.
   - Access your BIOS/UEFI setup utility (typically by pressing `DEL` or `F2` during boot).
   - **Enable CPU Virtualization**: Verify that Intel VT-x or AMD-V is enabled. Refer to your motherboard or CPU manual if needed.
   - Save changes and reboot into the USB installer.

4. **Run the Installer**:
   - Select **Install Proxmox VE** on the initial boot screen.
   - Follow the wizard to configure your target OS drive (e.g., your primary NVMe drive), timezone, root password, email, and management network settings.
   - For additional details, refer to the [Proxmox VE Installation Guide](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#chapter_installation).

---

## Initial Proxmox VE Access & Configuration

Once installation completes and the host reboots, the console will display the management URL (e.g., `https://<host-ip>:8006/`). Access this URL in your web browser and log in with the `root` username and the password configured during installation.

### Update Proxmox VE (No-Subscription Repositories)

By default, Proxmox VE is configured with enterprise package repositories that require a paid subscription. For home lab use, switch to the free community repositories:

1. Select your **Node** from the left-hand menu tree.
2. Navigate to **Updates** -> **Repositories**.
3. Select the two repository entries containing `enterprise` in their components and click **Disable** (disabling rather than deleting preserves them if you ever add a subscription).
4. Click **Add**:
   - Ignore the subscription warning dialog.
   - In the repository dropdown, select **No-Subscription** and click **Add**.
   - Repeat by clicking **Add** again, selecting **Ceph-Squid No-Subscription** (or current Ceph release), and clicking **Add**.
5. Navigate to **Updates** in the node menu and click **Refresh**.
6. Once the package index refreshes, click **Upgrade** to install all pending updates.
7. Repeat this process for all other physical nodes.

### Disable Subscription Warning Dialog (Optional Quality of Life)

Even after switching to the community repositories, the Proxmox VE Web UI displays a *"No valid subscription"* dialog upon each login. To silence this pop-up:

1. Open the **Shell** console for each node.
2. Run the following command to patch the Web UI toolkit script and reload the proxy service:
   ```bash
   sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service
   ```
3. Hard-refresh your browser (`Ctrl+F5` or `Cmd+Shift+R`) to reload the cached web assets.
4. *(Optional)* To ensure this patch automatically persists across future `proxmox-widget-toolkit` package upgrades, create an APT post-invoke hook:
   ```bash
   echo 'DPkg::Post-Invoke { "dpkg -V proxmox-widget-toolkit | grep -q \"/proxmoxlib\.js$\"; if [ $? -eq 1 ]; then { echo \"Patching Proxmox subscription nag...\"; sed -Ezi.bak \"s/(Ext.Msg.show\\(\\{\\s+title: gettext\\(\x27No valid sub)/void\\(\\{ \\/\\/\\1/g\" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service; }; fi"; };' > /etc/apt/apt.conf.d/no-nag-script
   ```
5. Repeat on all nodes in your cluster.

### Configure Static IP via Router DHCP Reservation

To ensure stable node addressing, assign a static DHCP reservation in your router using each node's MAC address:

1. Select your **Node** from the left-hand menu tree.
2. Click **Shell** in the top-right toolbar to open the host console.
3. Run `ip link` to list the network interfaces and their MAC addresses
4. Identify the MAC address of your management bridge (`vmbr0`) and confirm it matches the physical network adapter bridged to it.
5. In your router's administration portal, navigate to the **DHCP Server / Static Leases** section.
6. Create a static reservation binding the MAC address to the IP currently assigned to the host (preventing IP changes or DHCP address collisions).
7. Repeat for your remaining nodes.

---

## Create Datacenter / Proxmox Cluster

Clustering groups your independent Proxmox hosts into a unified management plane (see [Proxmox Cluster Management](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#chapter_cluster)).

1. Log into the web interface of your designated primary node.
2. In the left-hand menu tree, click **Datacenter**.
3. Select **Cluster** from the Datacenter menu.
4. Click **Create Cluster**, enter your desired cluster name (e.g., `lab-datacenter`), and click **Create**.
5. Once created, click **Join Information** and click **Copy Information** to copy the join token to your clipboard.
6. Log into your second Proxmox node's web GUI.
7. Navigate to **Datacenter** -> **Cluster** -> **Join Cluster**.
8. Paste the join information, enter the primary node's root password, and confirm.
9. After a brief reload, both nodes will be visible under the unified Datacenter view.

### 2-Node Cluster Quorum Considerations

> [!WARNING]
> **Understanding 2-Node Quorum & Split-Brain Protection**:
> Proxmox VE relies on [Corosync](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#pvecm_quorum) for cluster consensus. Corosync requires a strict majority vote ($> 50\%$) to maintain write quorum for `/etc/pve`:
> - In a **2-node cluster**, total votes = `2`. A majority requires **2 out of 2 votes**.
> - If **Node 1** reboots or goes offline for maintenance, **Node 2** has only 1 vote ($50\%$), and quorum is lost.
> - **Symptom**: When quorum is lost, `/etc/pve` becomes read-only. You will not be able to start, stop, migrate, or edit virtual machines from the remaining node until the offline node reconnects.

**Current Lab Strategy & Future Expansion**:
- **Future Scale**: This lab currently runs on 2 physical nodes based on available hardware, with plans to add more nodes in the future. Once a 3rd node is added, total votes will be 3, allowing a single node to fail or reboot without losing quorum ($2/3 > 50\%$).
- **Temporary Maintenance Workaround**:
  If one node is intentionally powered down for maintenance and you need to perform VM operations on the surviving active node, you can temporarily lower the required quorum threshold to 1 vote by running the following command in the active node's shell:
  ```bash
  pvecm expected 1
  ```
  *(Note: This temporary override automatically resets once the offline node powers back on and rejoins Corosync).*
- **Alternative (Corosync QDevice)**:
  If automated high availability is needed before physical hardware expansion, a lightweight tie-breaker vote called a **QDevice** can be configured on an external device (e.g., Raspberry Pi, NAS, or low-power mini-PC) via `pvecm qdevice setup <qdevice-ip>`.

---

## Initial Storage Drive Configuration

In this setup, each node utilizes two physical drives:
- **Primary NVMe SSD**: Hosts the Proxmox VE OS (`local`) and primary VM virtual disks (`local-lvm` / `local-zfs`).
- **Secondary SATA Drive (SSD/HDD)**: Dedicated storage for ISO images, container templates, and local VM backup dumps.

### Setup Secondary Drive as Directory Storage

1. Select your **Node** from the left-hand menu tree.
2. Navigate to **Disks** under the node menu.
3. Verify your secondary drive is displayed (click **Rescan** in the top right if it does not appear).
4. If the disk has existing partitions, select it, click **Wipe Disk**, and confirm with **Yes**.
5. In the node menu under **Disks**, select **Directory**.
6. Click **Create: Directory**:
   - **Disk**: Select your secondary disk.
   - **Filesystem**: Select `ext4`.
   - **Name**: Assign a descriptive identifier (e.g., `backup-storage` or `data-sata`).
   - Click **Create**.
7. Repeat this process on your other Proxmox node.
8. Once created, navigate to **Datacenter** -> **Storage** in the left-hand tree:
   - Select your secondary storage directory and click **Edit**.
   - Under **Content**, select all applicable content types: **ISO Image**, **VZDump backup file**, **Container template**, and **Disk image**.

---

## Proxmox Backup Server (PBS) & Future Planning

While secondary SATA drives provide local on-node backups, off-host backups are essential for disaster recovery:

- **Target Architecture**: Deploy a dedicated [Proxmox Backup Server (PBS)](https://pve.proxmox.com/wiki/Proxmox_Backup_Server) instance once dedicated NAS storage is available.
- **Benefits**: Client-side deduplication, incremental backups, and encrypted remote replication to an offsite location or S3-compatible cloud storage.

---

## Proxmox Host Hardening

Hardening the underlying hypervisor nodes protects the control layer of your infrastructure. This section outlines practical steps for network isolation, firewall enforcement, SSH restriction, and identity security.

---

### Network Security & Access Control

Below are recommended steps to secure and restrict network access to your Proxmox Datacenter.

#### VLAN Considerations

While optional for a small home lab, isolating management traffic, virtual machine workloads, and storage networks using VLANs is a standard production practice:
- **Management VLAN**: Restrict access to Proxmox VE Web UI (port `8006`), SSH, and IPMI/iDRAC.
- **Cluster Network**: Dedicated VLAN/bridge for Talos Linux nodes and Kubernetes workload traffic.
- **Storage Network**: Isolated network for NAS or storage replication if added in the future.

#### Restrict Web UI Access (Port 8006)

By default, the Proxmox VE Web UI is accessible from any IP address reaching the host. Restrict access to your management subnet or specific administrative workstations before enabling the firewall globally:

> [!IMPORTANT]
> **Safety Rule**: Always define and enable your **Allow** rule for management traffic *before* turning on the firewall globally to avoid locking yourself out of the web interface.

1. Select **Datacenter** in the left-hand navigation tree.
2. Select **Firewall** from the middle menu.
3. Click **Add** in the top toolbar to create an inbound allow rule:
   - **Direction**: `in`
   - **Action**: `ACCEPT`
   - **Source**: Enter your management subnet or trusted workstation IP (e.g., `192.168.0.0/24`).
   - **Protocol**: `tcp`
   - **Dest. Port**: `8006`
   - **Comment**: `Allow Web UI from management subnet`
4. Click **Add** to save the rule.
5. In the Firewall rules table, verify the checkbox in the **Enable** column is checked for the new rule.
6. Repeat this process for any additional administrative IP ranges as needed.

#### Enable Proxmox VE Firewall

Once your management allow rule is verified, activate the firewall at the Datacenter level:

1. Select **Datacenter** in the left-hand navigation tree.
2. Under **Firewall**, click **Options**.
3. Double-click the **Firewall** setting in the options table.
4. Check the **Firewall** checkbox to enable it and click **OK**.

#### Restrict SSH Access

Following the minimal, shell-less philosophy of Talos Linux, direct SSH access to the underlying Proxmox hypervisors should be tightly constrained. While SSH could theoretically be disabled entirely, Proxmox cluster nodes require SSH to communicate with one another (e.g., for cluster joins, live migrations, and configuration sync).

To restrict SSH to only cluster nodes and trusted management machines:

> [!WARNING]
> **Avoid Cluster Lockout**:
> Be sure to include the IP addresses of **all Proxmox cluster nodes** as well as your local management workstation in `/etc/hosts.allow`. Omitting node IPs will break inter-node communication and cluster management.

1. Open the **Shell** console for each node.
2. Edit `/etc/hosts.allow` using your preferred text editor (e.g., `nano /etc/hosts.allow`):
   ```text
   sshd: 127.0.0.1, <PVE_NODE_1_IP>, <PVE_NODE_2_IP>, <MANAGEMENT_WORKSTATION_IP>
   ```
3. Edit `/etc/hosts.deny` (`nano /etc/hosts.deny`) to deny all other incoming SSH connections:
   ```text
   sshd: ALL
   ```
4. Save and exit. Incoming SSH connection attempts from any unauthorized IP will now be immediately dropped.
5. Repeat this configuration across all nodes in the cluster.

---

### Identity & Access Management (IAM)

Hardening user access prevents unauthorized configuration changes and reduces reliance on the default root account.

#### Add a Dedicated Non-Root Administrator User

To practice the principle of least privilege, create a personal "daily driver" administrative user for day-to-day management through the Web UI. Direct console shell access remains isolated to the `root` account when maintenance is required:

1. Log into the Proxmox Web UI as `root`.
2. Select **Datacenter** in the left-hand navigation tree.
3. Select **Permissions** -> **Users** from the menu.
4. Click **Add** from the top toolbar:
   - **User name**: Choose your personal username (e.g., your preferred handle).
   - **Realm**: Select `Proxmox VE authentication server (pve)`.
   - **Password**: Enter and confirm a strong password.
   - Click **Add**.
5. Assign administrative permissions to the new user:
   - Navigate to **Datacenter** -> **Permissions**.
   - Click **Add** -> **User Permission**:
     - **Path**: `/` (root path to grant cluster-wide visibility)
     - **User**: Select your newly created user (e.g., `<username>@pve`)
     - **Role**: Select `Administrator`
     - **Propagate**: Checked
   - Click **Add**.
6. Log out and log back in using your new user account to confirm access.

#### Enable Two-Factor Authentication (2FA / TOTP)

While Proxmox supports multiple 2FA mechanisms (YubiKey, WebAuthn/Passkeys, TOTP, and SSO), an **Authenticator App (TOTP)** is the most practical baseline for a fresh lab setup:
- WebAuthn/Passkeys typically require a fully trusted HTTPS certificate (which may not yet be provisioned on self-signed IP addresses).
- An Identity Provider / SSO will eventually be hosted on top of this Kubernetes cluster, which would create a circular dependency during initial setup.

To configure TOTP:

1. Log into the Web UI with your target user account.
2. In the top-right corner, click on your username and select **TFA** (or navigate to **Datacenter** -> **Two-Factor** under **Permissions**).
3. Click **Add** and select **TOTP**.
4. Scan the presented QR code using your mobile authenticator app (e.g., 1Password, Bitwarden, Google Authenticator).
5. Enter the 6-digit verification code from your authenticator app and save.
6. Repeat this process for the `root` account as well to ensure all administrative access paths are protected.
7. Log out and verify that the portal prompts for your 2FA verification code upon login.

---

## Next Steps

With the hypervisor hosts installed, updated, clustered, partitioned, and hardened, proceed to:
- **`02-omni-machine-registration.md`** (Generating Omni boot media, setting up VM definitions, and onboarding nodes)
