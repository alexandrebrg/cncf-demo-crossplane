# Cloud Native Montpellier - ArgoCD & Crossplane Demo

This repository was originally made for the Cloud Native Montpellier meetup,
but as I found out that most Crossplane & ArgoCD tutorials are out-of-date or
inexistant, I made this simple repository giving keys to understand how it works.

A lot of things have been made "more simple" that it could be in production, and
WAYYY more splitted. It's better to understand the concepts :D

## Requirements

Add `argo.local` to your /etc/hosts

## Files

```
.
├── Makefile # You can find everything need to setup a k3d cluster, most important target: k3d-up
├── README.md # This file
├── 01-mcp-bootstrap # Helm chart: Install required apps to run our GitOps stuff (Install it manually)
│   ├── Chart.yaml
│   ├── charts
│   └── values.yaml
├── 01-zmcp-bootstrap # Some quick fix to run after 01
├── 02-mcp-apps # Helm chart: Install some sample apps (Trivy / Falco) (should be installed through 03)
│   ├── Chart.yaml
│   ├── charts
│   └── values.yaml
├── 03-install-apps # Create an ArgoCD application that will install 02-mcp-apps chart 
│   └── 02-aoa.yaml
├── 04-workers # Cluster CRDs to request two new clusters on GCP (takes sooo much time :angry:)
│   ├── 01-morty.yaml
│   └── 02-rik.yaml
├── 05-workers-bootstrap # Some manifest that will be installed through 06
│   └── 01-podtato.yaml
├── 06-install-workers # Create an Application that will be installed on RIK & Morty clusters
│   └── 01-podtato.yaml
├── 999-extra-definitions # Some extra to know how to manage more resources with crossplane
│   ├── 10-xrd.yaml
│   ├── 20-worker-definition.yaml
│   ├── 30-morty.yaml
│   └── 31-rik.yaml
├── mcp-bootstrap # Setup ArgoCD & Crossplane inside the MCP cluster
│   ├── Chart.lock
│   ├── Chart.yaml
│   └── values.yaml
```

## Steps

### Step 0

```shell
# Replace 01-mcp-bootstrap/templates/_00-secret-gcp.tpl by ../00-secret-gcp.yaml
# Update the file to include your GCP Service Account in base64 (see command in the file)
# Ref: https://cloud.google.com/iam/docs/service-accounts-create
```

### Step 1

```shell
# create k3d cluster
make k3d-up
# deploy mcp bootstrap
# This helm chart installs Crossplane + ArgoCD
helm upgrade --install --create-namespace mcp 01-mcp-bootstrap -n mcp
# deploy the fix for the config
kubectl apply -f 01-zmcp-bootstrap
```

### Step 2

```shell
kubectl apply -f 03-install-apps/
```

### Step 3

```shell
# Create 2 GKE clusters on GCP, wait 10 minutes from here to ensure they are running & healthy
kubectl apply -f 04-workers/

# You can check health here, wait until you see "running"
export CLUSTER_REGION="europe-north1"
export GCP_PROJECT_ID="REPLACE_ME"
gcloud container clusters describe "rik" --project ${GCP_PROJECT_ID} --zone "${CLUSTER_REGION}" \
    --format="value(status)"
gcloud container clusters describe "morty" --project ${GCP_PROJECT_ID} --zone "${CLUSTER_REGION}" \
    --format="value(status)"
```

### Step 4

```shell
export GCP_PROJECT_ID="REPLACE_ME"
export CLUSTER_REGION="europe-north1"
gcloud container clusters get-credentials rik --region ${CLUSTER_REGION}
kubectx "rik"=${GCP_PROJECT_ID}_${CLUSTER_REGION}_rik
kubectx rik
kubectl create ns argocd || true

gcloud container clusters get-credentials morty --region ${CLUSTER_REGION}
kubectx "morty"=${GCP_PROJECT_ID}_${CLUSTER_REGION}_morty
kubectx morty
kubectl create ns argocd || true

kubectx k3d-demo
```

### Step 5

```shell
# Credentials: admin / admin
# SAFETY FIRST :D
argocd login argo.local --grpc-web

# Register our clusters
argocd cluster add rik --namespace argocd \
    --grpc-web --name rik
argocd cluster add morty --namespace argocd \
    --grpc-web --name morty

# Check there are here
# UNKNOWN status is normal, don't worry ;D
argocd cluster list --grpc-web
```

### Step 6

```shell
# It will install podtato on both RIK & Morty clusters :D
kubectl apply -f 06-install-workers

# Enjoy podtato from here
```

## References

- [ArgoCD example apps](https://github.com/argoproj/argocd-example-apps)
- [Important Stuff](https://looks.wtf/)
- [Why RIK & Morty ?](https://www.youtube.com/watch?v=6LFDzlUsuRc&list=PLWdIy1tl_PkAHBurtWCoEsllO5zezoaYr&index=6)
- [Podtato](https://github.com/podtato-head/podtato-head)
- [Crossplane GKE Spec](https://marketplace.upbound.io/providers/upbound/provider-gcp-container/v0.38.1)