skip = !read_terragrunt_config(find_in_parent_folders("env.hcl")).locals.enable_eks

terraform {
  source = "${find_in_parent_folders("modules")}/aws-eks"
}


locals {
  account = include.root.locals.account_vars.locals.account_alias
  env     = include.root.locals.env_vars.locals.env
  cluster_endpoint_public_access_cidrs = [ "0.0.0.0/0" ]
}

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

# apply and destroy ordering
dependencies {
  paths = [
    "${get_terragrunt_dir()}/../network"
  ]
}

dependency "vpc" {
  config_path = "${get_terragrunt_dir()}/../network"
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
  tags = include.root.locals.tags
}
