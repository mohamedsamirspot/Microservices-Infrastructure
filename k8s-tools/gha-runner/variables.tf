variable "tags" {
  description = "Map of tags to assign"
  type        = map(string)
  default = {
    env         = "dev"
    terraform   = "true"
  }
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "EKS cluster CA certificate (base64 encoded)"
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
