kubectl create namespace ingress
helm install traefik oci://ghcr.io/joeckr/charts/ingress-traefik --version 0.1.1 --namespace ingress
