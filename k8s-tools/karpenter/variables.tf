variable "tags" {
  description = "Map of tags to assign"
  type        = map(string)
  default = {
    env         = "dev"
    terraform   = "true"
  }
}

variable "cluster_name" {
  type        = string
  default = "my-eks-cluster"
}

variable "kubernetes_version" {
  type    = string
  default = "1.34"
  description = "Kubernetes / EKS cluster version"
}

variable "cluster_endpoint" {
  type    = string
  default = ""
}

variable "cluster_certificate_authority_data" {
  type    = string
  default = ""
}