variable "secrets-store-csi-driver_chart_version" {
  description = "Version of the secrets-store-csi-driver Helm chart"
  type        = string
  default     = "1.5.5"
}

variable "secrets-store-csi-driver-provider-aws_chart_version" {
  description = "Version of the secrets-store-csi-driver-provider-aws Helm chart"
  type        = string
  default     = "2.1.1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  type        = string
}

variable "cluster_oidc_provider_url" {
  type        = string
}

variable "tags" {
  description = "Map of tags to assign"
  type        = map(string)
  default = {
    env         = "dev"
    terraform   = "true"
  }
}
