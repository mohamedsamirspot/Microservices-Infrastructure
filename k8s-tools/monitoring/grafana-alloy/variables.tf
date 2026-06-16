variable "alloy_chart_version" {
  description = "Version of the Grafana Alloy Helm chart. Keep empty to install the latest available chart version."
  type        = string
  default     = "1.10.0"
}

variable "cluster_name" {
  description = "Cluster name used as a static Loki label."
  type        = string
}

variable "loki_push_api_url" {
  description = "Loki push API endpoint URL used by Alloy."
  type        = string
  default     = "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
}

variable "namespace_selector_regex" {
  description = "Regex used to keep only selected namespaces for pod log collection."
  type        = string
  default     = ".*"
}

variable "enable_service_monitor" {
  description = "Create ServiceMonitor resource for Alloy metrics scraping. Requires monitoring.coreos.com/v1 CRDs."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Map of tags to assign. Kept for consistency with other modules."
  type        = map(string)
  default = {
    env       = "dev"
    terraform = "true"
  }
}
