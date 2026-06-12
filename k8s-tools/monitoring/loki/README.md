Loki (monolithic) Helm + Terraform
=================================

This directory contains Terraform code to provision an S3 bucket and a Helm release to install Grafana Loki in a single-replica, monolithic configuration for testing.

Files
- `main.tf` — Namespace, S3 bucket, public access block, and `helm_release` for Loki.
- `variables.tf` — Module variables for chart version, region and bucket name.
- `values-loki.yaml` — Templated Helm values (uses `templatefile` placeholders `${s3_bucket}` and `${region}`).

Usage
1. Configure AWS provider and backend at a parent level (this module does not configure providers).
2. Optionally set `bucket_name` in `variables.tf` or pass it when calling the module.
3. Run `terraform init` and `terraform apply` from the parent that includes this module.

Notes
- This setup creates an S3 bucket but does not create Kubernetes credentials or IAM roles for pods to access S3.
- For testing, you can provide AWS credentials to Loki via a Kubernetes secret and mount them, or use IRSA on EKS and adjust the chart values accordingly.
