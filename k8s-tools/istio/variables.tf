variable "istio_chart_version" {
  description = "Version of the istio-base/istiod/gateway Helm charts (must be kept in sync across all three)"
  type        = string
  default     = "1.30.4"
}
