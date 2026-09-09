skip = !read_terragrunt_config(find_in_parent_folders("env.hcl")).locals.enable_aws_eks

terraform {
  source = "${find_in_parent_folders("aws-modules")}/aws-eks"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  account = read_terragrunt_config(find_in_parent_folders("account.hcl")).locals.account_id
  env     = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals.env
  cluster_endpoint_public_access_cidrs = [ "0.0.0.0/0" ]
}

# apply and destroy ordering
dependencies {
  paths = [
    "${get_terragrunt_dir()}/../aws-network"
  ]
}

dependency "vpc" {
  config_path = "${get_terragrunt_dir()}/../aws-network"
    # Fix for run-all init
  mock_outputs = {
    vpc_id                = "vpc-mock"
    private_subnet_ids    = ["subnet-mock1", "subnet-mock2"]
  }
}

inputs = {
  cluster_name                         = "${local.account}-${local.env}-eks"
  vpc_id                               = dependency.vpc.outputs.vpc_id
  subnet_ids                           = dependency.vpc.outputs.private_subnet_ids
  cluster_endpoint_public_access_cidrs = local.cluster_endpoint_public_access_cidrs
  tags = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals.tags

  # Istio's istiod webhook (sidecar-injector/validation) listens on 15017, which isn't in the module's
  # own default webhook port allow-list, only opened when the istio k8s-tools module is actually enabled.
  additional_node_security_group_rules = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals.enable_istio ? {
    ingress_cluster_to_node_istiod_webhook = {
      description                   = "Cluster API to node groups for istiod webhook (sidecar-injector/validation)"
      protocol                      = "tcp"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }
  } : {}
}
