variable "envoy-gateway-api_chart_version" {
  description = "Version of the envoy-gateway-api Helm chart"
  type        = string
  default     = "1.6.2"
}

variable "envoy-crds_chart_version" {
  description = "Version of the custome-envoy-crds Helm chart"
  type        = string
  default     = "1.6.2"
}