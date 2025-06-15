variable "cluster_name" {
  type        = string
  default = "my-eks-cluster"
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
  default = [ "45.245.75.56/32" ]
}

variable "instance_type" {
  type        = list(string)
  default = ["t3.medium"] 
}

variable "volume_size" {
  type        = number
  default = 50
}

variable "min_size" {
  type        = number
  default = 2
}

variable "max_size" {
  type        = number
  default = 3
}

variable "desired_size" {
  type        = number
  default = 2
}

# variable "principal_arn" {
#   type        = string
#   default = "arn:aws:iam::948763340657:user/spot"
# }

variable "tags" {
  description = "Map of tags to assign"
  type        = map(string)
  default = {
    Project     = "eks-cluster"
    env         = "prod"
    # Owner       = "devops-team"
  }
}

variable "vpc_id" {
  type        = string
}

variable "subnet_ids" {
  type        = list(string)
}

# variable "control_plane_subnet_ids" {
#   type        = list(string)
# }
