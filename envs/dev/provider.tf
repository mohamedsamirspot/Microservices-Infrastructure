provider "aws" {
  region = var.region
}


terraform {
  required_version = ">= 1.11.0" # Keep the minimum version constraint of terraform itself

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0"
      # >= 6.0 → allows any version 6.0 and above (includes breaking changes in future versions).
      # ~> 5.0 → allows versions 5.x only (safe from breaking changes).
      # 👉 Use ~> 5.0 for stability, and >= 6.0 only if you always want the newest version.
    }
  }

  # varaiables are not supported in the backend block in terraform
  # backend "local" {
  #   path = "dev/terraform.tfstate"
  # }

  backend "s3" {
    bucket       = "terraform-state-multi-env-spot"
    key          = "dev/eks-cluster/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

