variable "tags" {
  description = "Map of tags to assign"
  type        = map(string)
  default = {
    env         = "dev"
    terraform   = "true"
  }
}

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
