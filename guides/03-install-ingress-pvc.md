# 03 - Install Ingress & PVC

This guide covers installing Traefik as the ingress controller on the Talos cluster using Helm, followed by persistent volume claim (PVC) setup.

## Why Traefik?

The two main options for an ingress controller in Kubernetes are typically NGINX and Traefik. While NGINX tends to be the default, it is not natively rootless, whereas Traefik is, making it a natural fit for a hardened Talos Linux cluster enforcing Pod Security Standards (`Restricted`).

Both controllers are supported in this homelab:
- **Traefik** (default): [joeckr/lab-traefik-ingress](https://github.com/joeckr/lab-traefik-ingress)
- **NGINX**: [joeckr/lab-nginx-ingress](https://github.com/joeckr/lab-nginx-ingress)

For the steps in this guide and commands in the script, you can simply replace the word `traefik` with `nginx` if you prefer NGINX. The repositories are structured so that it is easy to swap between the two.

## Installing Traefik

Unless you have custom requirements, installation is straightforward. Run the [scripts/install-ingress.sh](file:///Users/josephking/Code/lab/cluster/lab-talos-cluster/scripts/install-ingress.sh) script:

```bash
./scripts/install-ingress.sh
```

Under the hood, the script pulls the pre-hardened OCI Helm chart package from GitHub Packages (GHCR) and installs it into the `ingress` namespace:

```bash
helm install traefik oci://ghcr.io/joeckr/charts/ingress-traefik --version 0.1.1 --namespace ingress
```

If you prefer NGINX, swap the chart and release name:

```bash
helm install ingress-nginx oci://ghcr.io/joeckr/charts/ingress-nginx --version 0.1.2 --namespace ingress
```

Verify that the ingress controller pods and `LoadBalancer` service are running:

```bash
kubectl get pods,svc -n ingress
```

If you need alterations to the installation or values overrides, you can reference the wrapper chart repositories:
- [joeckr/lab-traefik-ingress](https://github.com/joeckr/lab-traefik-ingress)
- [joeckr/lab-nginx-ingress](https://github.com/joeckr/lab-nginx-ingress)

## Persistent Storage & PVC

*(Persistent volume controller and storage provisioner setup will be added here).*
