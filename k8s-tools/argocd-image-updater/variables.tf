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

variable "argocd_chart_version" {
  description = "Version of the argocd-image-updater Helm chart"
  type        = string
  default     = "1.0.1"
}