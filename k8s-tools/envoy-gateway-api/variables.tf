variable "envoy-gateway-api_chart_version" {
  description = "Version of the envoy-gateway-api Helm chart"
  type        = string
  default     = "1.6.2"
}

variable "custome-envoy-gateway-crds_chart_version" {
  description = "Version of the custome-envoy-gateway-crds Helm chart"
  type        = string
  default     = "1.6.2"
}