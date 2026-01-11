variable "grafana_chart_version" {
  description = "Version of the grafana Helm chart"
  type        = string
  default     = "10.5.5"
}

variable "tags" {
  description = "Map of tags to assign"
  type        = map(string)
  default = {
    env         = "dev"
    terraform   = "true"
  }
}
