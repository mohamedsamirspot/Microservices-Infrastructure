variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "argocd-image-updater_chart_version" {
  description = "Version of the argocd-image-updater Helm chart"
  type        = string
  default     = "0.14.0"
}
