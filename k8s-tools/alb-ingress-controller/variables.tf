variable "vpcId" {
  type    = string
  default = ""
}

variable "cluster_name" {
  type        = string
  default = "my-eks-cluster"
}


variable "oidc_provider_arn" {
  type    = string
  default = ""
}
