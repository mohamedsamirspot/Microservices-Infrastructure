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

variable "github_app_id" {
  description = "GitHub App ID"
  type        = string
  default     = "2314309"
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = string
  default     = "95382986"
}

variable "runner_sizes" {
  type    = list(string)
  default = ["small", "medium", "large"]
}
