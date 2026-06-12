variable "loki_chart_version" {
  description = "Version of the loki Helm chart. Pin to a specific chart version."
  type        = string
  default     = "17.3.2"
}

variable "aws_region" {
  description = "AWS region for S3 bucket"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Optional S3 bucket name for Loki storage. If blank, a name will be generated."
  type        = string
  default     = "loki-storage"
}

variable "tags" {
  description = "Map of tags to assign"
  type        = map(string)
  default = {
    env       = "dev"
    terraform = "true"
  }
}
