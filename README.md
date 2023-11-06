## Requirements

Add `argo.local` to your /etc/hosts


## Step 0

```shell
# Replace primary-config/templates/_00-secret-gcp.tpl by ../00-secret-gcp.yaml
# Update the file to include your GCP Service Account in base64 (see command in the file)
# Ref: https://cloud.google.com/iam/docs/service-accounts-create
```
## Step 1

```shell
# create k3d cluster
make k3d-up
# deploy primary
helm upgrade --install --create-namespace primary primary-bootstrap
```