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

variable "stakater-reloader_chart_version" {
  description = "Version of the stakater-reloader Helm chart"
  type        = string
  default     = "chart-v2.2.6"
}