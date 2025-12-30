variable "name" {
  type        = string
  default = "my-efs"
}

variable "tags" {
  description = "Map of tags to assign"
  type        = map(string)
  default = {
    project     = "eks-cluster"
    env         = "env"
    terraform   = "true"
  }
}

variable "vpc_id" {
  type        = string
}
variable "private_subnets" {
  type        = list(string)
}
variable "private_subnets_cidr_blocks" {
  type        = list(string)
}
