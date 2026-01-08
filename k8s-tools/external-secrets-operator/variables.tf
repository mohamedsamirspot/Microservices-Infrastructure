variable "external-secrets-operator_chart_version" {
  description = "Version of the external-secrets-operator Helm chart"
  type        = string
  default     = "1.2.1"
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
