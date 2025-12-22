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
  description = "Version of the ArgoCD Helm chart"
  type        = string
  default     = "9.0.5"
}
