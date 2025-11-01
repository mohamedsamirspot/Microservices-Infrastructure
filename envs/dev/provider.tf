provider "aws" {
  region = var.region
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]

    }
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
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
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
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

