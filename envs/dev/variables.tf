variable "region" {
  type        = string
}

variable "cluster_name" {
  type        = string
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
}