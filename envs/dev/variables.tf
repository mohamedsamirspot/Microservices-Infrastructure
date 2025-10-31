#------------------------------------------------------------------------
variable "env" {
  description = "Environment name (default: current folder name)"
  type        = string
  default     = ""
}

locals {
  env = var.env != "" ? var.env : basename(path.cwd)
}

output "env" {
  value = local.env
}
#------------------------------------------------------------------------

variable "region" {
  type        = string
}

variable "cluster_name" {
  type        = string
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
}