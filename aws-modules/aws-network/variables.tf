variable "name" {
  type        = string
  default = "eks-vpc"
}

variable "cidr" {
  type        = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type        = list(string)
  default = ["us-east-1a", "us-east-1b"] # Use only two availability zones
}

variable "private_subnets" {
  type        = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  type        = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"] # Two public subnets for the control plane --> at least two subnets and must be specified in at least two different AZs
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

variable "cluster_name" {
  type        = string
}
