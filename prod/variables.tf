variable "region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1" # Update as needed
}




#------------------------------general variables as both modules (network and eks) depend on it------------------------------------
variable "cluster_name" {
  type        = string
  default     = "my-eks-cluster"
}

variable "env" {
  type        = string
  default     = "prod"
}
#----------------------------------------------------------------------------------------------------------------------------------

