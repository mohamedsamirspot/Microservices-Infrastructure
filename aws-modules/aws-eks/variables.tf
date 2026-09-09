variable "cluster_name" {
  type        = string
  default = "my-eks-cluster"
}

variable "kubernetes_version" {
  type    = string
  default = "1.36"
  description = "Kubernetes / EKS cluster version to create and to use as a default for addon compatibility."
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
  #default = [ "41.130.126.210/32" ]
  default = [ "0.0.0.0/0" ]
}

variable "instance_type" {
  type        = list(string)
  default = ["t3.medium"]  # 2 nodes (2 cores, 2 rams) for karpenter
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
    project     = "eks-cluster"
    env         = "env"
    terraform   = "true"
  }
}

variable "vpc_id" {
  type        = string
}

variable "subnet_ids" {
  type        = list(string)
}

variable "additional_node_security_group_rules" {
  # This module doesn't need to know what any of these are for (Istio, another webhook, etc.),
  # it just merges whatever the caller passes in on top of the module's own default rules.
  description = "Extra node security group rules to merge in on top of this module's defaults, keyed by rule name (aws_eks module's node_security_group_additional_rules format)"
  type        = any
  default     = {}
}

# variable "control_plane_subnet_ids" {
#   type        = list(string)
# }
