provider "aws" {
  region = var.region
}


terraform {
  required_version = ">= 1.11.0" # Keep the minimum version constraint of terraform itself

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
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

