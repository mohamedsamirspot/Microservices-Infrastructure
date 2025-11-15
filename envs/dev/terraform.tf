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


    # required_providers is a module-level declaration and is not automatically “passed” down. Provider configuration blocks (provider "name" { ... }) from the root are handed to child modules when the provider type (namespace/name) matches, but the child should still declare the provider names it expects in its own terraform { required_providers { ... } } to avoid warnings and to be explicit.
    # so this required providers block here is for the root module and not for the child modules but we still need to declare them here for kubectl and helm authentication which is defined in the provider.tf here to work in the child modules
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
