apiVersion: v1
kind: Secret
metadata:
  name: gcp-account-creds
type: Opaque
data:
  credentials: "" # Replace here with a base64 of your GCP Service Account
  # $ cat sa.json | base64 | tr -d "\\n"
