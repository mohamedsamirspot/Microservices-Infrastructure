variable "loki_chart_version" {
  description = "Version of the loki Helm chart. Pin to a specific chart version."
  type        = string
  default     = "17.3.2"
}

variable "aws_region" {
  description = "AWS region for S3 bucket"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name used for naming IRSA resources"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN for EKS cluster"
  type        = string
}

variable "cluster_oidc_provider_url" {
  description = "OIDC issuer URL for EKS cluster"
  type        = string
}

variable "bucket_name" {
  description = "Optional S3 bucket name for Loki storage. If blank, a name will be generated."
  type        = string
  default     = "loki-storage"
}

variable "tags" {
  description = "Map of tags to assign"
  type        = map(string)
  default = {
    env       = "dev"
    terraform = "true"
  }
}
