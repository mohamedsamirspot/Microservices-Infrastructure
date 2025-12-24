variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "argocd_chart_version" {
  description = "Version of the ArgoCD Helm chart"
  type        = string
  default     = "9.0.5"
}
