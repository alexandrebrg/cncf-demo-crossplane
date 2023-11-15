# Cloud Native Montpellier - ArgoCD & Crossplane Demo

## Requirements

Add `argo.local` to your /etc/hosts

## Files

```
.
├── Makefile # You can find everything need to setup a k3d cluster
├── README.md # This file
├── 01-mcp-bootstrap # Helm chart: Install required apps to run our GitOps stuff (Install it manually)
│   ├── Chart.yaml
│   ├── charts
│   └── values.yaml
├── 02-mcp-apps # Helm chart: Install some sample apps (Trivy / Falco) (should be installed through 03)
│   ├── Chart.yaml
│   ├── charts
│   └── values.yaml
├── 03-install-apps # Create an ArgoCD application that will install 02-mcp-apps chart 
│   └── 02-aoa.yaml
├── 04-workers # Cluster CRDs to request two new clusters on GCP ()
│   ├── 01-morty.yaml
│   └── 02-rik.yaml
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

## References

- [ArgoCD example apps](https://github.com/argoproj/argocd-example-apps)
- [Important Stuff](https://looks.wtf/)
- [Why RIK & Morty ?](https://www.youtube.com/watch?v=6LFDzlUsuRc&list=PLWdIy1tl_PkAHBurtWCoEsllO5zezoaYr&index=6)