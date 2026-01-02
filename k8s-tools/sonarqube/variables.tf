variable "sonarqube_chart_version" {
  description = "Version of the sonarqube Helm chart"
  type        = string
  default     = "2025.6.1"
}

variable "vpc_id" {
  type        = string
}

variable "vpc_cidr_block" {
  type        = string
}

variable "database_subnet_group_name" {
  type        = string
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
