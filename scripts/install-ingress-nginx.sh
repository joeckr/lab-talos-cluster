#!/usr/bin/env bash

kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace ingress-nginx pod-security.kubernetes.io/enforce=privileged --overwrite

cd ../charts || exit
helm dependency build ingress-nginx

helm install ingress-nginx -n ingress-nginx ingress-nginx/

kubectl get pods -n ingress-nginx -o wide
